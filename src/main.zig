const std = @import("std");
const mem = std.mem;
const os = std.os;

const Tree = @import("tree.zig").Tree;

const Surface = @import("surface.zig").Surface;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const OutputInfo = @import("surface.zig").OutputInfo;
const xdgOutputListener = @import("surface.zig").xdgOutputListener;

const Seat = @import("seat.zig").Seat;
const seatListener = @import("seat.zig").seatListener;

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const cairo = @import("cairo");

const EventInterfaces = enum {
    wl_shm,
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
    zxdg_output_manager_v1,
};

const Grid = struct {
    size: [2]u32 = .{ 80, 80 },
    offset: [2]u32 = .{ 0, 0 },
};

pub const Seto = struct {
    shm: ?*wl.Shm = null,
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    seat: Seat,
    outputs: std.ArrayList(Surface),
    grid: Grid = Grid{},
    alloc: mem.Allocator,

    fn new() Seto {
        const alloc = std.heap.page_allocator;
        return .{
            .seat = Seat.new(),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
        };
    }

    // TODO: This is definetly not gonna work on multi monitor but couldnt be bothered rn
    fn getDimensions(self: *Seto) [2]c_int {
        var dimensions: [2]c_int = .{ 0, 0 };
        for (self.outputs.items) |output| {
            dimensions[0] += output.output_info.width;
            dimensions[1] += output.output_info.height;
        }

        return dimensions;
    }

    // TODO: reverse the order of filling out without initializing new ArrayList
    fn getIntersections(self: *Seto) !std.ArrayList([2]usize) {
        const dimensions = self.getDimensions();
        var intersections = std.ArrayList([2]usize).init(self.alloc);
        var i: usize = self.grid.offset[0] % self.grid.size[0];
        while (i <= dimensions[0]) : (i += self.grid.size[0]) {
            var j: usize = self.grid.offset[1] % self.grid.size[1];
            while (j <= dimensions[1]) : (j += self.grid.size[1]) {
                try intersections.append(.{ i, j });
            }
        }

        var in = std.ArrayList([2]usize).init(self.alloc);
        for (intersections.items) |_| {
            try in.append(intersections.popOrNull().?);
        }

        return in;
    }

    fn correctgetIntersections(self: *Seto) !std.ArrayList([2]usize) {
        const dimensions = self.getDimensions();
        var intersections = std.ArrayList([2]usize).init(self.alloc);
        var i: usize = @as(usize, @intCast(dimensions[0])) + self.grid.offset[0];
        while (i >= self.grid.size[0]) : (i -= self.grid.size[0]) {
            var j: usize = @as(usize, @intCast(dimensions[1])) + self.grid.offset[1];
            while (j >= self.grid.size[1]) : (j -= self.grid.size[1]) {
                try intersections.append(.{ i - self.grid.size[0], j - self.grid.size[1] });
            }
        }

        return intersections;
    }

    fn createSurfaces(self: *Seto) !void {
        const keys = [_]*const [1:0]u8{ "a", "s", "d", "f", "g", "h", "j", "k", "l" };
        if (keys.len <= 1) {
            std.debug.print("Error: keys length must be greater than 1\n", .{});
            std.os.exit(1);
        }

        const dimensions = self.getDimensions();
        const width: u32 = @intCast(dimensions[0]);
        const height: u32 = @intCast(dimensions[1]);

        var intersections = try self.correctgetIntersections();
        defer intersections.deinit();

        var depth: usize = @intFromFloat(std.math.ceil(std.math.log(f64, keys.len, @as(f64, @floatFromInt(intersections.items.len)))));

        var tree = try Tree.new(self.alloc, &keys, depth, &intersections);
        defer tree.destroy();
        const tree_paths = try tree.iter(&keys);
        defer self.alloc.free(tree_paths);

        const cairo_surface = try cairo.ImageSurface.create(.argb32, @intCast(width), @intCast(height));
        defer cairo_surface.destroy();
        const context = try cairo.Context.create(cairo_surface.asSurface());
        defer context.destroy();

        context.setSourceRgb(0.5, 0.5, 0.5);
        context.paintWithAlpha(0.5);
        context.setSourceRgb(1, 1, 1);

        for (tree_paths) |item| {
            context.moveTo(@floatFromInt(item.pos[0]), 0);
            context.lineTo(@floatFromInt(item.pos[0]), @floatFromInt(height));
            context.moveTo(0, @floatFromInt(item.pos[1]));
            context.lineTo(@floatFromInt(width), @floatFromInt(item.pos[1]));

            context.moveTo(@floatFromInt(item.pos[0] + 5), @floatFromInt(item.pos[1] + 15));
            context.selectFontFace("JetBrainsMono Nerd Font", .Normal, .Normal);
            context.setFontSize(16);
            context.showText(item.path);
        }

        context.stroke();
        const data = try cairo_surface.getData();

        const size: i32 = @intCast(width * height * 4);

        for (self.outputs.items) |*output| {
            if (!output.is_configured()) continue;
            const fd = try os.memfd_create("seto", 0);
            defer os.close(fd);
            try os.ftruncate(fd, @intCast(size));

            const shm = self.shm orelse return error.NoWlShm;
            const pool = try shm.createPool(fd, size);
            defer pool.destroy();

            try output.draw(pool, fd, data);
        }
    }

    fn destroy(self: *Seto) void {
        self.compositor.?.destroy();
        self.layer_shell.?.destroy();
        self.shm.?.destroy();
        self.output_manager.?.destroy();
        for (self.outputs.items) |*output| {
            output.destroy();
        }
        self.outputs.deinit();
        self.seat.destroy();
    }
};

pub fn main() !void {
    const display = try wl.Display.connect(null);
    defer display.disconnect();

    const registry = try display.getRegistry();
    defer registry.destroy();

    var seto = Seto.new();
    defer seto.destroy();

    registry.setListener(*Seto, registryListener, &seto);

    while (!seto.seat.exit) {
        if (display.roundtrip() != .SUCCESS) return error.RoundtripFailed;
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        try seto.createSurfaces();
    }

    if (@import("builtin").mode == .Debug) { // Clear font cache to remove the "memory leaks" from valgrind output
        const c_cairo = @cImport(@cInclude("cairo.h"));
        const c_font = @cImport(@cInclude("fontconfig/fontconfig.h"));

        c_font.FcFini();
        c_cairo.cairo_debug_reset_static_data();
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const events = std.meta.stringToEnum(EventInterfaces, std.mem.span(global.interface)) orelse return;
            switch (events) {
                .wl_shm => {
                    seto.shm = registry.bind(global.name, wl.Shm, wl.Shm.generated_version) catch return;
                },
                .wl_compositor => {
                    seto.compositor = registry.bind(global.name, wl.Compositor, wl.Compositor.generated_version) catch return;
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch return;
                },
                .wl_output => {
                    const global_output = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch return;

                    const compositor = seto.compositor orelse return;
                    const surface = compositor.createSurface() catch return;

                    const layer_surface = seto.layer_shell.?.getLayerSurface(surface, global_output, .overlay, "seto") catch return;
                    layer_surface.setListener(*Seto, layerSurfaceListener, seto);
                    layer_surface.setAnchor(.{
                        .top = true,
                        .right = true,
                        .bottom = true,
                        .left = true,
                    });
                    layer_surface.setExclusiveZone(-1);
                    layer_surface.setKeyboardInteractivity(.exclusive);
                    surface.commit();

                    const xdg_output = seto.output_manager.?.getXdgOutput(global_output) catch return;

                    const output_info = OutputInfo{ .alloc = seto.alloc, .wl = global_output };
                    const output = Surface.new(surface, layer_surface, seto.alloc, xdg_output, output_info);

                    xdg_output.setListener(*Seto, xdgOutputListener, seto);

                    seto.outputs.append(output) catch return;
                },
                .wl_seat => {
                    const wl_seat = registry.bind(global.name, wl.Seat, wl.Seat.generated_version) catch return;
                    seto.seat.wl_seat = wl_seat;
                    wl_seat.setListener(*Seto, seatListener, seto);
                },
                .zxdg_output_manager_v1 => {
                    seto.output_manager = registry.bind(
                        global.name,
                        zxdg.OutputManagerV1,
                        zxdg.OutputManagerV1.generated_version,
                    ) catch return;
                },
            }
        },
        .global_remove => |remove_event| {
            std.log.warn("Global Removed {any}", .{remove_event});
        },
    }
}
