const std = @import("std");
const mem = std.mem;
const os = std.os;

const Tree = @import("tree.zig").Tree;
const OutputInfo = @import("surface.zig").OutputInfo;
const Surface = @import("surface.zig").Surface;
const Seat = @import("seat.zig").Seat;
const Result = @import("tree.zig").Result;

const handleKey = @import("seat.zig").handleKey;

const xdgOutputListener = @import("surface.zig").xdgOutputListener;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;

const wayland = @import("wayland");
const xkb = @import("xkbcommon");
const cairo = @import("cairo");

const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

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

    depth: usize = 0,

    redraw: bool = false,
    first_draw: bool = true,
    exit: bool = false,

    const Self = @This();

    fn new(alloc: mem.Allocator) Self {
        return .{
            .seat = Seat.new(alloc),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
        };
    }

    // TODO: Make it multi output
    fn getDimensions(self: *Self) [2]c_int {
        var dimensions: [2]c_int = .{ 0, 0 };
        for (self.outputs.items, 0..) |output, i| {
            if (output.isConfigured() and i == 0) {
                dimensions[0] += output.output_info.width;
                dimensions[1] += output.output_info.height;
            }
        }

        return dimensions;
    }

    fn getIntersections(self: *Seto) ![][2]usize {
        const dimensions = self.getDimensions();
        const width: u32 = @intCast(dimensions[0]);
        const height: u32 = @intCast(dimensions[1]);

        var intersections = std.ArrayList([2]usize).init(self.alloc);
        defer intersections.deinit();
        var i: usize = self.grid.offset[0] % self.grid.size[0];
        while (i <= width) : (i += self.grid.size[0]) {
            var j: usize = self.grid.offset[1] % self.grid.size[1];
            while (j <= height) : (j += self.grid.size[1]) {
                try intersections.append(.{ i, j });
            }
        }

        return try intersections.toOwnedSlice();
    }

    fn updateDepth(self: *Self, intersections: [][2]usize, keys: []const *const [1:0]u8) void {
        const items_len: f64 = @floatFromInt(intersections.len);
        const keys_len: f64 = @floatFromInt(keys.len);
        const depth = std.math.log(f64, keys_len, items_len);
        self.depth = @intFromFloat(std.math.ceil(depth));
    }

    fn removeWrongChar(self: *Self, branch_info: []Result) void {
        var any_matches = false;
        for (branch_info) |branch| {
            if (self.seat.buffer.items.len == 0) {
                any_matches = true;
                break;
            }
            const len = self.seat.buffer.items.len - 1;
            if (std.mem.eql(u8, self.seat.buffer.items[len][0..1], branch.path[len .. len + 1])) {
                any_matches = true;
            }
        }

        if (!any_matches) {
            _ = self.seat.buffer.pop();
        }
    }

    fn createSurfaces(self: *Self) !void {
        if (!self.drawSurfaces()) return;

        const keys = [_]*const [1:0]u8{ "a", "s", "d", "f", "g", "h", "j", "k", "l" };
        if (keys.len <= 1) {
            std.debug.print("Error: keys length must be greater than 1\n", .{});
            std.os.exit(1);
        }

        const dimensions = self.getDimensions();
        const width: u32 = @intCast(dimensions[0]);
        const height: u32 = @intCast(dimensions[1]);

        var intersections = try self.getIntersections();
        defer self.alloc.free(intersections);

        self.updateDepth(intersections, &keys);

        var tree = try Tree.new(self.alloc, &keys, self.depth, intersections);
        const branch_info = try tree.iter(&keys);
        self.removeWrongChar(branch_info);
        defer tree.alloc.deinit();
        tree.find(self.seat.buffer.items);

        const cairo_surface = try cairo.ImageSurface.create(.argb32, @intCast(width), @intCast(height));
        defer cairo_surface.destroy();
        const context = try cairo.Context.create(cairo_surface.asSurface());
        defer context.destroy();

        context.setSourceRgb(0.5, 0.5, 0.5);
        context.paintWithAlpha(0.5);
        context.setSourceRgb(1, 1, 1);

        for (branch_info) |branch| {
            var matching: u8 = 0;
            for (self.seat.buffer.items, 0..) |char, i| {
                if (std.mem.eql(u8, char[0..1], branch.path[i .. i + 1])) {
                    matching += 1;
                    continue;
                }

                matching = 0;
                break;
            }

            context.moveTo(@floatFromInt(branch.pos[0]), 0);
            context.lineTo(@floatFromInt(branch.pos[0]), @floatFromInt(height));
            context.moveTo(0, @floatFromInt(branch.pos[1]));
            context.lineTo(@floatFromInt(width), @floatFromInt(branch.pos[1]));

            context.moveTo(@floatFromInt(branch.pos[0] + 5), @floatFromInt(branch.pos[1] + 15));
            context.selectFontFace("JetBrainsMono Nerd Font", .Normal, .Normal);
            context.setFontSize(16);
            for (0..self.depth) |i| {
                if (i < matching) {
                    context.setSourceRgb(1, 1, 0);
                }
                var positions: [2]u8 = undefined;
                positions[0] = branch.path[i];
                positions[1] = 0;
                context.showText(positions[0..1 :0]);
                context.setSourceRgb(1, 1, 1);
            }
        }

        context.stroke();
        const data = try cairo_surface.getData();

        const size: i32 = @intCast(width * height * 4);

        // TODO: Make it multi output
        for (self.outputs.items, 0..) |*output, i| {
            if (!output.isConfigured() or i > 0) continue;
            const fd = try os.memfd_create("seto", 0);
            defer os.close(fd);
            try os.ftruncate(fd, @intCast(size));

            const shm = self.shm orelse return error.NoWlShm;
            const pool = try shm.createPool(fd, size);
            defer pool.destroy();

            try output.draw(pool, fd, data);
        }
    }

    fn drawSurfaces(self: *Self) bool {
        const draw = self.redraw or self.first_draw;
        self.first_draw = false;
        return draw;
    }

    fn destroy(self: *Self) void {
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

    var dbg_gpa = if (@import("builtin").mode == .Debug) std.heap.GeneralPurposeAllocator(.{}){} else {};
    defer if (@TypeOf(dbg_gpa) != void) {
        _ = dbg_gpa.deinit();
    };
    const alloc = if (@TypeOf(dbg_gpa) != void) dbg_gpa.allocator() else std.heap.c_allocator;

    var seto = Seto.new(alloc);
    defer seto.destroy();

    registry.setListener(*Seto, registryListener, &seto);
    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;

    while (!seto.exit) {
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        if (seto.seat.repeatKey()) {
            handleKey(&seto);
        }
        try seto.createSurfaces();
        if (seto.seat.repeat.rate) |repeat_rate| {
            const rate: u64 = @intCast(repeat_rate);
            std.time.sleep(rate * std.time.ns_per_ms);
        }
    }

    // Clear font cache in debug to remove the "memory leaks" from valgrind output
    if (@import("builtin").mode == .Debug) {
        const c_cairo = @cImport(@cInclude("cairo.h"));
        const c_font = @cImport(@cInclude("fontconfig/fontconfig.h"));

        c_font.FcFini();
        c_cairo.cairo_debug_reset_static_data();
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const event_str = std.meta.stringToEnum(EventInterfaces, std.mem.span(global.interface)) orelse return;
            switch (event_str) {
                .wl_shm => {
                    seto.shm = registry.bind(global.name, wl.Shm, wl.Shm.generated_version) catch |err| @panic(@errorName(err));
                },
                .wl_compositor => {
                    seto.compositor = registry.bind(global.name, wl.Compositor, wl.Compositor.generated_version) catch |err| @panic(@errorName(err));
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch |err| @panic(@errorName(err));
                },
                .wl_output => {
                    const global_output = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch |err| @panic(@errorName(err));

                    const compositor = seto.compositor orelse @panic("Compositor not bound");
                    const surface = compositor.createSurface() catch |err| @panic(@errorName(err));

                    const layer_surface = seto.layer_shell.?.getLayerSurface(surface, global_output, .overlay, "seto") catch |err| @panic(@errorName(err));
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

                    const xdg_output = seto.output_manager.?.getXdgOutput(global_output) catch |err| @panic(@errorName(err));

                    const output_info = OutputInfo{ .alloc = seto.alloc, .wl = global_output };
                    const output = Surface.new(surface, layer_surface, seto.alloc, xdg_output, output_info, global.name);

                    xdg_output.setListener(*Seto, xdgOutputListener, seto);

                    seto.outputs.append(output) catch |err| @panic(@errorName(err));
                },
                .wl_seat => {
                    const wl_seat = registry.bind(global.name, wl.Seat, wl.Seat.generated_version) catch |err| @panic(@errorName(err));
                    seto.seat.wl_seat = wl_seat;
                    wl_seat.setListener(*Seto, seatListener, seto);
                },
                .zxdg_output_manager_v1 => {
                    seto.output_manager = registry.bind(
                        global.name,
                        zxdg.OutputManagerV1,
                        zxdg.OutputManagerV1.generated_version,
                    ) catch |err| @panic(@errorName(err));
                },
            }
        },

        .global_remove => |global_removed| {
            for (seto.outputs.items, 0..) |output, i| {
                if (output.name == global_removed.name) _ = seto.outputs.swapRemove(i);
            }
        },
    }
}
