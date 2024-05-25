const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const Tree = @import("tree.zig").Tree;
const Tree2 = @import("tree.zig").Tree2;
const OutputInfo = @import("surface.zig").OutputInfo;
const Surface = @import("surface.zig").Surface;
const Seat = @import("seat.zig").Seat;
const Result = @import("tree.zig").Result;
const Config = @import("config.zig").Config;

const handleKey = @import("seat.zig").handleKey;

const xdgOutputListener = @import("surface.zig").xdgOutputListener;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;

const parseArgs = @import("cli.zig").parseArgs;

const cairo = @import("cairo");

const wayland = @import("wayland");
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

pub const Mode = union(enum) {
    Region: ?[2]isize,
    Single,
};

pub const Seto = struct {
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    shm: ?*wl.Shm = null,
    seat: Seat,
    outputs: std.ArrayList(Surface),
    config: ?Config = null,
    first_draw: bool = true,
    exit: bool = false,
    mode: Mode = .Single,
    config_path: ?[:0]const u8 = null,
    alloc: mem.Allocator,

    const Self = @This();

    fn new(alloc: mem.Allocator) Self {
        return .{
            .seat = Seat.new(alloc),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
        };
    }

    fn getDimensions(self: *Self) [2]i32 {
        var x: [2]i32 = .{ 0, 0 };
        var y: [2]i32 = .{ 0, 0 };
        for (self.outputs.items) |output| {
            if (!output.isConfigured()) continue;
            const info = output.output_info;

            if (info.x < x[0]) x[0] = info.x;
            if (info.y < y[0]) y[0] = info.y;
            if (info.x + info.width > x[1]) x[1] = info.x + info.width;
            if (info.y + info.height > y[1]) y[1] = info.y + info.height;
        }

        return .{ x[1] - x[0], y[1] - y[0] };
    }

    fn sortOutputs(self: *Self) void {
        std.mem.sort(Surface, self.outputs.items, self.outputs.items[0], comptime Surface.cmp);
    }

    fn getIntersections(self: *Seto) [][2]isize {
        const dimensions = self.getDimensions();
        const width: u32 = @intCast(dimensions[0]);
        const height: u32 = @intCast(dimensions[1]);

        const grid = self.config.?.grid;

        const num_steps_i = @divTrunc((width - grid.offset[0]), grid.size[0]) + 1;
        const num_steps_j = @divTrunc((height - grid.offset[1]), grid.size[1]) + 1;

        const total_intersections = num_steps_i * num_steps_j;

        var intersections = self.alloc.alloc([2]isize, @intCast(total_intersections)) catch @panic("OOM");

        var index: usize = 0;
        var i = grid.offset[0];
        while (i <= width) : (i += grid.size[0]) {
            var j = grid.offset[1];
            while (j <= height) : (j += grid.size[1]) {
                intersections[index] = .{ i, j };
                index += 1;
            }
        }

        return intersections;
    }

    fn drawGrid(self: *Self, width: u32, height: u32, context: *const *cairo.Context) void {
        const grid = self.config.?.grid;
        var i: isize = grid.offset[0];
        while (i <= width) : (i += grid.size[0]) {
            context.*.moveTo(@floatFromInt(i), 0);
            context.*.lineTo(@floatFromInt(i), @floatFromInt(height));
        }

        i = grid.offset[1];
        while (i <= height) : (i += grid.size[1]) {
            context.*.moveTo(0, @floatFromInt(i));
            context.*.lineTo(@floatFromInt(width), @floatFromInt(i));
        }

        context.*.setSourceRgba(grid.color[0], grid.color[1], grid.color[2], grid.color[3]);
        context.*.stroke();

        switch (self.mode) {
            .Region => |position| if (position) |pos| {
                context.*.moveTo(0, @floatFromInt(pos[1]));
                context.*.lineTo(@floatFromInt(width), @floatFromInt(pos[1]));

                context.*.moveTo(@floatFromInt(pos[0]), 0);
                context.*.lineTo(@floatFromInt(pos[0]), @floatFromInt(height));

                context.*.setSourceRgba(grid.selected_color[0], grid.selected_color[1], grid.selected_color[2], grid.selected_color[3]);
                context.*.stroke();
            },
            .Single => {},
        }
    }

    fn printToStdout(self: *Self, tree: *Tree) void {
        const coords = tree.find(self.seat.buffer.items) catch |err| {
            switch (err) {
                error.KeyNotFound => _ = self.seat.buffer.popOrNull(),
                error.EndNotReached => {},
            }
            return;
        };
        switch (self.mode) {
            .Region => |positions| {
                if (positions) |pos| {
                    const top_left: [2]isize = .{ @min(coords[0], pos[0]), @min(coords[1], pos[1]) };
                    const bottom_right: [2]isize = .{ @max(coords[0], pos[0]), @max(coords[1], pos[1]) };
                    const size: [2]isize = .{ bottom_right[0] - top_left[0], bottom_right[1] - top_left[1] };
                    const format = std.fmt.allocPrintZ(self.alloc, "{},{} {}x{}\n", .{ top_left[0], top_left[1], size[0], size[1] }) catch @panic("OOM");
                    defer self.alloc.free(format);
                    _ = std.io.getStdOut().write(format) catch @panic("Write error");
                    self.exit = true;
                } else {
                    self.mode = .{ .Region = coords };
                    self.seat.buffer.clearAndFree();
                }
            },
            .Single => {
                const positions = std.fmt.allocPrintZ(self.alloc, "{},{}\n", .{ coords[0], coords[1] }) catch @panic("OOM");
                defer self.alloc.free(positions);
                _ = std.io.getStdOut().write(positions) catch @panic("Write error");
                self.exit = true;
            },
        }
    }

    fn createSurfaces(self: *Self) !void {
        if (!self.shouldDraw()) return;
        self.sortOutputs();

        const dimensions = self.getDimensions();
        const width: u32 = @intCast(dimensions[0]);
        const height: u32 = @intCast(dimensions[1]);

        const intersections = self.getIntersections();
        defer self.alloc.free(intersections);

        const depth = getDepth(intersections, self.config.?.keys.search);

        var tree = Tree.new(self.alloc, self.config.?.keys.search, depth, intersections);
        defer tree.alloc.deinit();

        self.printToStdout(&tree);
        if (self.exit) {
            const outputs = self.outputs.items;
            for (outputs) |*output| {
                if (!output.isConfigured()) continue;
                const data = try self.alloc.alloc(u8, @intCast(output.output_info.width * output.output_info.height * 4));
                defer self.alloc.free(data);
                @memset(data, 0);

                try output.draw(data.ptr);
            }
            return;
        }

        const cairo_surface = try cairo.ImageSurface.create(.argb32, @intCast(width), @intCast(height));
        defer cairo_surface.destroy();
        const ctx = try cairo.Context.create(cairo_surface.asSurface());
        defer ctx.destroy();

        tree.drawText(ctx, self.config.?.font, self.seat.buffer.items, self.config.?.font.offset, self.mode);
        self.drawGrid(width, height, &ctx);

        const bg_color = self.config.?.background_color;
        ctx.setSourceRgb(bg_color[0], bg_color[1], bg_color[2]);
        ctx.paintWithAlpha(bg_color[3]);

        var prev: ?OutputInfo = null;
        var pos: [2]i32 = .{ 0, 0 };

        const outputs = self.outputs.items;
        for (outputs) |*output| {
            if (!output.isConfigured()) continue;
            const info = output.output_info;
            const output_surface = try cairo.ImageSurface.create(.argb32, @intCast(info.width), @intCast(info.height));
            defer output_surface.destroy();
            const output_ctx = try cairo.Context.create(output_surface.asSurface());
            defer output_ctx.destroy();

            if (prev) |p| {
                if (info.x <= p.x) pos = .{ 0, p.height };
            }

            output_ctx.setSourceSurface(cairo_surface.asSurface(), @floatFromInt(-pos[0]), @floatFromInt(-pos[1]));
            pos[0] += info.width;
            output_ctx.paint();

            const data = try output_surface.getData();
            try output.draw(data);
            prev = info;
        }
    }

    fn shouldDraw(self: *Self) bool {
        defer self.first_draw = false;
        return self.seat.repeat.key != null or self.first_draw;
    }

    fn destroy(self: *Self) void {
        self.compositor.?.destroy();
        self.layer_shell.?.destroy();
        self.output_manager.?.destroy();
        self.shm.?.destroy();

        for (self.outputs.items) |*output| {
            output.destroy();
        }
        self.outputs.deinit();
        self.seat.destroy();
        self.config.?.keys.bindings.deinit();
        self.config.?.destroy();
        if (self.config_path) |path|
            self.alloc.free(path);
    }
};

fn getDepth(intersections: [][2]isize, keys: []const u8) u8 {
    const items_len: f64 = @floatFromInt(intersections.len);
    const keys_len: f64 = @floatFromInt(keys.len);
    const depth = std.math.log(f64, keys_len, items_len);
    return @intFromFloat(std.math.ceil(depth));
}

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

    parseArgs(&seto);

    const config = Config.load(alloc, seto.config_path) catch @panic("");
    seto.config = config;

    registry.setListener(*Seto, registryListener, &seto);
    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;
    var timer = try std.time.Timer.start();
    while (true) {
        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
        if (seto.seat.repeatKey()) handleKey(&seto);
        try seto.createSurfaces();
        if (seto.exit) {
            if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
            break;
        }
        std.debug.print("{}\n", .{timer.lap() / std.time.ns_per_ms});
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const event_str = std.meta.stringToEnum(EventInterfaces, mem.span(global.interface)) orelse return;
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

                    const output_info = OutputInfo{ .wl_output = global_output };
                    const output = Surface.new(surface, layer_surface, seto.alloc, xdg_output, output_info, seto.shm.?);

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
        .global_remove => {}, // TODO: Implement remove output (not very important tho)
    }
}
