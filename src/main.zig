const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const c = @import("ffi");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const Tree = @import("Tree.zig");
const OutputInfo = @import("Output.zig").OutputInfo;
const Output = @import("Output.zig");
const Seat = @import("seat.zig").Seat;
const Config = @import("Config.zig");
const Egl = @import("Egl.zig");
const Text = @import("config/Text.zig");
const EventLoop = @import("EventLoop.zig");

const handleKey = @import("seat.zig").handleKey;
const xdgOutputListener = @import("Output.zig").xdgOutputListener;
const layerSurfaceListener = @import("Output.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;
const parseArgs = @import("cli.zig").parseArgs;
const inPlaceReplace = @import("helpers").inPlaceReplace;
const wlOutputListener = @import("Output.zig").wlOutputListener;

const EventInterfaces = enum {
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
    zxdg_output_manager_v1,
};

pub const Mode = union(enum) {
    Region: ?[2]f32,
    Single,
};

pub const State = struct {
    first_draw: bool = true,
    exit: bool = false,
    mode: Mode = .Single,
    border_mode: bool = false,
};

pub const Seto = struct {
    egl: Egl,
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    seat: Seat,
    outputs: std.ArrayList(Output),
    config: Config,
    alloc: mem.Allocator,
    tree: ?Tree = null,
    total_dimensions: [2]f32 = .{ 0, 0 },
    state: State = State{},

    const Self = @This();

    fn init(alloc: mem.Allocator, display: *wl.Display) !Self {
        var seto = Seto{
            .seat = try Seat.init(alloc),
            .outputs = std.ArrayList(Output).init(alloc),
            .alloc = alloc,
            .egl = try Egl.init(display),
            .config = try Config.load(alloc),
        };

        parseArgs(&seto);

        if (seto.config.keys.search.len < 2) {
            std.log.err("Minimum two search keys have to be set\n", .{});
            std.process.exit(1);
        }

        seto.config.grid.max_size[1] = seto.config.font.size + seto.config.font.offset[1];
        seto.config.text = Text.init(alloc, &seto.config);

        return seto;
    }

    pub fn updateDimensions(self: *Self) void {
        // Sort outputs from left to right row by row
        std.mem.sort(Output, self.outputs.items, self.outputs.items[0], Output.cmp);

        const first = self.outputs.items[0].info;
        const last = self.outputs.getLast().info;

        self.total_dimensions = .{ (last.x + last.width) - first.x, (last.y + last.height) - first.y };
    }

    fn formatOutput(self: *Self, arena: *std.heap.ArenaAllocator, top_left: [2]f32, size: [2]f32) void {
        for (self.outputs.items) |output| {
            if (!output.isConfigured()) continue;

            if (output.posInSurface(top_left)) {
                const relative_pos = .{ top_left[0] - output.info.x, top_left[1] - output.info.y };
                const relative_size = .{
                    @abs(top_left[0] - @min((output.info.x + output.info.width), top_left[0] + size[0])),
                    @abs(top_left[1] - @min((output.info.y + output.info.height), top_left[1] + size[1])),
                };

                const output_name = if (output.info.name) |name| name else "<unkown>";

                inPlaceReplace([]const u8, arena.allocator(), &self.config.output_format, "%o", output_name);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%X", @intFromFloat(relative_pos[0]));
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%Y", @intFromFloat(relative_pos[1]));
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%W", @intFromFloat(relative_size[0]));
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%H", @intFromFloat(relative_size[1]));

                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%x", @intFromFloat(top_left[0]));
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%y", @intFromFloat(top_left[1]));
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%w", @intFromFloat(size[0]));
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%h", @intFromFloat(size[1]));

                return;
            }
        }
    }

    pub fn printToStdout(self: *Self) !void {
        const coords = try self.tree.?.find(&self.seat.buffer.items);
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();

        switch (self.state.mode) {
            .Single => self.formatOutput(&arena, coords, .{ 1, 1 }),
            .Region => |positions| if (positions) |pos| {
                const top_left: [2]f32 = .{ @min(coords[0], pos[0]), @min(coords[1], pos[1]) };
                const bottom_right: [2]f32 = .{ @max(coords[0], pos[0]), @max(coords[1], pos[1]) };

                const width = bottom_right[0] - top_left[0];
                const height = bottom_right[1] - top_left[1];

                const size: [2]f32 = .{ if (width == 0) 1 else width, if (height == 0) 1 else height };

                self.formatOutput(&arena, top_left, size);
            } else {
                self.state.mode = .{ .Region = coords };
                self.seat.buffer.clearAndFree();
                return;
            },
        }

        _ = std.io.getStdOut().write(self.config.output_format) catch @panic("Write error");
        self.state.exit = true;
    }

    pub fn render(self: *Self) !void {
        for (self.outputs.items) |*output| {
            if (!output.isConfigured()) continue;
            try output.egl.makeCurrent();

            output.draw(&self.config, self.state.border_mode, &self.state.mode);
            self.tree.?.drawText(output, &self.config, self.seat.buffer.items, self.state.border_mode);

            try output.egl.swapBuffers();
        }
    }

    fn deinit(self: *Self) void {
        self.compositor.?.destroy();
        self.layer_shell.?.destroy();
        self.output_manager.?.destroy();
        for (self.outputs.items) |*output| {
            output.deinit();
        }
        self.outputs.deinit();
        self.seat.deinit();
        self.config.deinit();
        self.tree.?.arena.deinit();
        self.egl.deinit();
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

    var seto = try Seto.init(alloc, display);
    defer seto.deinit();

    const timer = &seto.seat.repeat.timer;

    registry.setListener(*Seto, registryListener, &seto);
    if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
    if (display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    if (seto.layer_shell == null) @panic("wlr_layer_shell not supported");

    try seto.render();

    var event_loop = EventLoop.init(alloc);
    defer event_loop.deinit();

    try event_loop.insertSource(display.getFd(), *wl.Display, dispatchDisplay, display);
    try event_loop.insertSource(timer.getFd(), *Seto, handleRepeat, &seto);

    while (!seto.state.exit) : (try event_loop.poll()) {}

    for (seto.outputs.items) |output| {
        try output.egl.makeCurrent();
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        try output.egl.swapBuffers();
    }

    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;
}

fn dispatchDisplay(display: *wl.Display) void {
    if (display.dispatch() != .SUCCESS) {
        std.log.err("Failed to dispatch events", .{});
        return;
    }
}

fn handleRepeat(seto: *Seto) void {
    const repeats = seto.seat.repeat.timer.read() catch {
        std.log.err("Failed to read timer fd", .{});
        return;
    };

    for (0..repeats) |_| handleKey(seto);
    seto.render() catch {
        std.log.err("Failed to render", .{});
        return;
    };
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, seto: *Seto) void {
    switch (event) {
        .global => |global| {
            const event_str = std.meta.stringToEnum(EventInterfaces, mem.span(global.interface)) orelse return;
            switch (event_str) {
                .wl_compositor => {
                    seto.compositor = registry.bind(
                        global.name,
                        wl.Compositor,
                        wl.Compositor.generated_version,
                    ) catch @panic("Failed to bind wl_compositor");
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(
                        global.name,
                        zwlr.LayerShellV1,
                        zwlr.LayerShellV1.generated_version,
                    ) catch @panic("Failed to bind zwl_layer_shell");
                },
                .wl_output => {
                    const wl_output = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch @panic("Failed to bind wl_output");
                    wl_output.setListener(*Seto, wlOutputListener, seto);

                    const surface = seto.compositor.?.createSurface() catch @panic("Failed to create surface");

                    const layer_surface = seto.layer_shell.?.getLayerSurface(
                        surface,
                        wl_output,
                        .overlay,
                        "seto",
                    ) catch @panic("Failed to get layer surface");
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

                    const xdg_output = seto.output_manager.?.getXdgOutput(wl_output) catch @panic("Failed to get xdg output global");

                    const egl_surface = seto.egl.surfaceInit(surface, .{ 1, 1 }) catch @panic("Failed to create egl surface");

                    const output = Output.init(
                        egl_surface,
                        surface,
                        layer_surface,
                        seto.alloc,
                        xdg_output,
                        wl_output,
                        OutputInfo{ .id = global.name },
                    );

                    xdg_output.setListener(*Seto, xdgOutputListener, seto);

                    seto.outputs.append(output) catch @panic("OOM");
                },
                .wl_seat => {
                    seto.seat.wl_seat = registry.bind(
                        global.name,
                        wl.Seat,
                        wl.Seat.generated_version,
                    ) catch @panic("Failed to bind seat global");
                    seto.seat.wl_seat.?.setListener(*Seto, seatListener, seto);
                },
                .zxdg_output_manager_v1 => {
                    seto.output_manager = registry.bind(
                        global.name,
                        zxdg.OutputManagerV1,
                        zxdg.OutputManagerV1.generated_version,
                    ) catch @panic("Failed to bind output manager global");
                },
            }
        },
        .global_remove => |global| {
            for (seto.outputs.items, 0..) |*output, i| {
                if (output.info.id == global.name) {
                    output.deinit();
                    _ = seto.outputs.swapRemove(i);
                    seto.updateDimensions();
                    return;
                }
            }
        },
    }
}
