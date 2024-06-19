const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;
const c = @import("ffi.zig");

const Tree = @import("tree.zig").Tree;
const OutputInfo = @import("surface.zig").OutputInfo;
const Surface = @import("surface.zig").Surface;
const SurfaceIterator = @import("surface.zig").SurfaceIterator;
const Seat = @import("seat.zig").Seat;
const Result = @import("tree.zig").Result;
const Config = @import("config.zig").Config;
const Egl = @import("egl.zig").Egl;

const handleKey = @import("seat.zig").handleKey;
const xdgOutputListener = @import("surface.zig").xdgOutputListener;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;
const parseArgs = @import("cli.zig").parseArgs;

const EventInterfaces = enum {
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
    zxdg_output_manager_v1,
};

pub const Mode = union(enum) {
    Region: ?[2]i32,
    Single,

    const Self = @This();

    pub fn withinBounds(self: *const Self, info: OutputInfo) bool {
        return self.xWithinBounds(info) and self.yWithinBounds(info);
    }

    pub fn xWithinBounds(self: *const Self, info: OutputInfo) bool {
        switch (self.*) {
            .Region => |position| if (position) |pos| {
                return pos[0] >= info.x and pos[0] <= info.x + info.width;
            },
            .Single => {},
        }

        return false;
    }

    pub fn yWithinBounds(self: *const Self, info: OutputInfo) bool {
        switch (self.*) {
            .Region => |position| if (position) |pos| {
                return pos[1] >= info.y and pos[1] <= info.y + info.width;
            },
            .Single => {},
        }

        return false;
    }
};

pub const Seto = struct {
    egl: Egl,
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    seat: Seat,
    outputs: std.ArrayList(Surface),
    config: Config,
    alloc: mem.Allocator,
    tree: ?Tree = null,
    total_dimensions: [2]i32 = .{ 0, 0 },

    first_draw: bool = true,
    exit: bool = false,
    mode: Mode = .Single,
    border_mode: bool = false,

    const Self = @This();

    fn new(alloc: mem.Allocator, display: *wl.Display) !Self {
        return .{
            .seat = Seat.new(alloc),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
            .config = Config.load(alloc),
            .egl = try Egl.new(display),
        };
    }

    pub fn updateDimensions(self: *Self) void {
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

        self.total_dimensions = .{ x[1] - x[0], y[1] - y[0] };
    }

    pub fn sortOutputs(self: *Self) void {
        std.mem.sort(Surface, self.outputs.items, self.outputs.items[0], Surface.cmp);
    }

    fn formatOutput(self: *Self, arena: *std.heap.ArenaAllocator, top_left: [2]i32, size: [2]i32, outputs: []Surface) void {
        var pos: [2]i32 = .{ 0, 0 };
        var output_name: []const u8 = "<unkown>";
        for (outputs, 0..) |*output, i| {
            if (!output.isConfigured()) continue;
            const info = output.output_info;

            if (i > 0) {
                if (info.x <= outputs[i - 1].output_info.x) pos = .{ 0, outputs[i - 1].output_info.height };
            }

            if (output.posInSurface(top_left)) {
                const relative_pos = .{ top_left[0] - info.x, top_left[1] - info.y };
                const relative_size = .{ @abs(top_left[0] - @min((info.x + info.width), top_left[0] + size[0])), @abs(top_left[1] - @min((info.y + info.height), top_left[1] + size[1])) };
                output_name = if (info.name) |name| name else "<unkown>";
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%X", relative_pos[0]);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%Y", relative_pos[1]);
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%W", relative_size[0]);
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%H", relative_size[1]);
            }

            pos[0] += info.width;
        }

        inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%x", top_left[0]);
        inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%y", top_left[1]);
        inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%w", size[0]);
        inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%h", size[1]);
        inPlaceReplace([]const u8, arena.allocator(), &self.config.output_format, "%o", output_name);
    }

    fn printToStdout(self: *Self) !void {
        const coords = try self.tree.?.find(self.seat.buffer.items);
        switch (self.mode) {
            .Region => |positions| {
                if (positions) |pos| {
                    const top_left: [2]i32 = .{ @min(coords[0], pos[0]), @min(coords[1], pos[1]) };
                    const bottom_right: [2]i32 = .{ @max(coords[0], pos[0]), @max(coords[1], pos[1]) };
                    const size: [2]i32 = .{ bottom_right[0] - top_left[0], bottom_right[1] - top_left[1] };

                    var arena = std.heap.ArenaAllocator.init(self.alloc);
                    defer arena.deinit();
                    self.formatOutput(&arena, top_left, size, self.outputs.items);

                    _ = std.io.getStdOut().write(self.config.output_format) catch @panic("Write error");
                    self.exit = true;
                } else {
                    self.mode = .{ .Region = coords };
                    self.seat.buffer.clearAndFree();
                }
            },
            .Single => {
                var arena = std.heap.ArenaAllocator.init(self.alloc);
                defer arena.deinit();
                _ = self.formatOutput(&arena, coords, .{ 1, 1 }, self.outputs.items);

                _ = std.io.getStdOut().write(self.config.output_format) catch @panic("Write error");
                self.exit = true;
            },
        }
    }

    fn createSurfaces(self: *Self) !void {
        if (!self.shouldDraw()) return;
        self.printToStdout() catch |err| {
            switch (err) {
                error.KeyNotFound => {
                    _ = self.seat.buffer.popOrNull();
                    return;
                },
                else => {},
            }
        };

        var surf_iter = SurfaceIterator.new(self.outputs.items);
        var start_pos: [2]?i32 = .{ null, null };
        while (surf_iter.next()) |res| {
            var surface, _, const new_line = res;

            if (!surface.isConfigured()) continue;
            try self.egl.makeCurrent(surface.egl);

            const bg = self.config.background_color;
            c.glClearColor(
                @floatCast(bg[0] * bg[3]),
                @floatCast(bg[1] * bg[3]),
                @floatCast(bg[2] * bg[3]),
                @floatCast(bg[3]),
            );
            c.glClear(c.GL_COLOR_BUFFER_BIT);

            c.glUseProgram(self.egl.shader_program);
            const color = self.config.grid.color;
            c.glUniform4f(0, color[0], color[1], color[2], color[3]);
            const result: [2]?i32 = if (new_line) .{ null, start_pos[1] } else .{ start_pos[0], null };
            start_pos = surface.draw(result, self.mode);

            try surface.egl.getEglError();
            c.glUseProgram(0);
            try self.egl.swapBuffers(surface.egl);
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
        for (self.outputs.items) |*output| {
            output.destroy();
        }
        self.outputs.deinit();
        self.seat.destroy();
        self.config.destroy();
        self.tree.?.arena.deinit();
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

    var seto = try Seto.new(alloc, display);
    defer seto.destroy();

    parseArgs(&seto);

    registry.setListener(*Seto, registryListener, &seto);
    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;

    if (seto.compositor == null or seto.layer_shell == null) {
        std.debug.print("Compositor, layer_shell or shm not bound", .{});
        std.process.exit(1);
    }

    while (display.dispatch() == .SUCCESS and !seto.exit) {
        if (seto.seat.repeatKey()) handleKey(&seto);
        try seto.createSurfaces();
    }

    var surf_iter = SurfaceIterator.new(seto.outputs.items);
    while (surf_iter.next()) |res| {
        const surface = res.@"0";
        try seto.egl.makeCurrent(surface.egl);
        c.glClearColor(0, 0, 0, 0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        try seto.egl.swapBuffers(surface.egl);
    }

    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const event_str = std.meta.stringToEnum(EventInterfaces, mem.span(global.interface)) orelse return;
            switch (event_str) {
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

                    const surface = seto.compositor.?.createSurface() catch |err| @panic(@errorName(err));

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

                    const egl_surface = seto.egl.newSurface(surface, .{ 1, 1 }) catch return;

                    const output = Surface.new(
                        egl_surface,
                        surface,
                        layer_surface,
                        seto.alloc,
                        xdg_output,
                        OutputInfo{ .id = global.name },
                        &seto.config,
                    );

                    xdg_output.setListener(*Seto, xdgOutputListener, seto);

                    seto.outputs.append(output) catch |err| @panic(@errorName(err));
                },
                .wl_seat => {
                    seto.seat.wl_seat = registry.bind(global.name, wl.Seat, wl.Seat.generated_version) catch |err| @panic(@errorName(err));
                    seto.seat.wl_seat.?.setListener(*Seto, seatListener, seto);
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
        .global_remove => |global| {
            for (seto.outputs.items, 0..) |*output, i| {
                if (output.output_info.id == global.name) {
                    output.destroy();
                    _ = seto.outputs.swapRemove(i);
                    seto.sortOutputs();
                }
            }
        },
    }
}

fn inPlaceReplace(comptime T: type, alloc: std.mem.Allocator, input: *[]const u8, needle: []const u8, replacement: T) void {
    const count = std.mem.count(u8, input.*, needle);
    if (count == 0) return;
    const str = if (T == []const u8)
        std.fmt.allocPrint(alloc, "{s}", .{replacement}) catch @panic("OOM")
    else
        std.fmt.allocPrint(alloc, "{}", .{replacement}) catch @panic("OOM");

    const buffer = alloc.alloc(u8, count * str.len + (input.*.len - needle.len * count)) catch @panic("OOM");
    _ = std.mem.replace(u8, input.*, needle, str, buffer);
    input.* = buffer;
}
