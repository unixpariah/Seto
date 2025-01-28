const std = @import("std");
const c = @import("ffi");
const wayland = @import("wayland");
const zgl = @import("zgl");

const wl = wayland.client.wl;
const mem = std.mem;
const posix = std.posix;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const Tree = @import("Tree/NormalTree.zig");
const Output = @import("Output.zig");
const Config = @import("Config.zig");
const Egl = @import("Egl.zig");
const Text = @import("config/Text.zig");
const EventLoop = @import("EventLoop.zig");
const Trees = @import("Tree/Trees.zig");
const OutputInfo = @import("Output.zig").OutputInfo;
const Seat = @import("seat.zig").Seat;
const Font = @import("config/Font.zig");
const Grid = @import("config/Grid.zig");
const Keys = @import("config/Keys.zig");

const getLuaFile = @import("Config.zig").getLuaFile;
const handleKey = @import("seat.zig").handleKey;
const xdgOutputListener = @import("Output.zig").xdgOutputListener;
const layerSurfaceListener = @import("Output.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;
const inPlaceReplace = @import("helpers").inPlaceReplace;
const wlOutputListener = @import("Output.zig").wlOutputListener;

const EventInterfaces = enum {
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    wl_seat,
    zxdg_output_manager_v1,
};

pub const TotalDimensions = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    pub fn updateDimensions(outputs: []OutputInfo) TotalDimensions {
        // Sort outputs from left to right row by row
        std.mem.sort(OutputInfo, outputs, outputs[0], OutputInfo.cmp);

        const first = outputs[0];
        var index: usize = outputs.len - 1;
        const last = while (index > 0) : (index -= 1) {
            if (outputs[index].height != 0 and outputs[index].width != 0) break outputs[index];
        } else first;

        return .{
            .x = first.x,
            .y = first.y,
            .width = (last.x + last.width - 1) - first.x,
            .height = (last.y + last.height - 1) - first.y,
        };
    }
};

pub const State = struct {
    exit: bool = false,
    border_mode: bool = false,
    buffer: std.ArrayList(u32),
    total_dimensions: TotalDimensions = .{},

    pub fn deinit(self: *State) void {
        self.buffer.deinit();
    }
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
    state: State,
    trees: ?Trees = null,

    const Self = @This();

    fn init(alloc: mem.Allocator, seat: Seat, egl: Egl, config: Config) !Self {
        return Seto{
            .seat = seat,
            .outputs = std.ArrayList(Output).init(alloc),
            .alloc = alloc,
            .egl = egl,
            .config = config,
            .state = .{ .buffer = std.ArrayList(u32).init(alloc) },
        };
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
        const trees = self.trees orelse return;
        const coords = try trees.find(&self.state.buffer.items) orelse return;
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();

        switch (self.config.mode) {
            .Single => self.formatOutput(&arena, coords, .{ 1, 1 }),
            .Region => |positions| if (positions) |pos| {
                const top_left: [2]f32 = .{ @min(coords[0], pos[0]), @min(coords[1], pos[1]) };
                const bottom_right: [2]f32 = .{ @max(coords[0], pos[0]), @max(coords[1], pos[1]) };

                const width = bottom_right[0] - top_left[0];
                const height = bottom_right[1] - top_left[1];

                const size: [2]f32 = .{ if (width == 0) 1 else width, if (height == 0) 1 else height };

                self.formatOutput(&arena, top_left, size);
            } else {
                self.config.mode = .{ .Region = coords };
                self.state.buffer.clearAndFree();
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

            _ = c.eglSwapInterval(output.egl.display.*, 0);

            output.draw(&self.config, self.state);
            self.trees.?.drawText(output, self.state.buffer.items);

            try output.egl.swapBuffers();
        }
    }

    fn deinit(self: *Self) void {
        self.state.deinit();
        if (self.compositor) |compositor| compositor.destroy();
        if (self.layer_shell) |layer_shell| layer_shell.destroy();
        if (self.output_manager) |output_manager| output_manager.destroy();
        for (self.outputs.items) |*output| output.deinit();
        self.outputs.deinit();
        self.seat.deinit();
        self.config.deinit();
        self.egl.deinit();
        if (self.trees) |trees| trees.deinit();
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

    var lua = try getLuaFile(alloc);
    defer lua.deinit();

    var font = Font.init(lua, alloc);
    var grid = Grid.init(lua, alloc);
    var keys = try Keys.init(lua, alloc);
    const config = try Config.load(lua, &keys, &grid, &font, alloc);

    const seat = try Seat.init(alloc);
    const egl = try Egl.init(alloc, display);
    var seto = try Seto.init(alloc, seat, egl, config);
    defer seto.deinit();

    var text = try Text.init(alloc, keys.search, font.family);
    seto.config.text = &text;

    registry.setListener(*Seto, registryListener, &seto);
    if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
    if (display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    if (seto.layer_shell == null) @panic("wlr_layer_shell not supported");

    var event_loop = try EventLoop.initCapacity(alloc, -1, 2);
    defer event_loop.deinit();

    event_loop.insertSourceAssumeCapacity(display.getFd(), *wl.Display, dispatchDisplay, display);
    event_loop.insertSourceAssumeCapacity(seto.seat.repeat.timer.getFd(), *Seto, handleRepeat, &seto);

    try seto.render();

    while (!seto.state.exit) : (try event_loop.poll()) {}

    for (seto.outputs.items) |output| {
        try output.egl.makeCurrent();
        zgl.clear(.{ .color = true });
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
    const repeats = seto.seat.repeat.timer.read() catch blk: {
        std.log.err("Failed to read timer fd", .{});
        break :blk 1;
    };

    for (0..repeats) |_| handleKey(seto);
    seto.render() catch std.log.err("Failed to render", .{});
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

                    const surface = seto.compositor.?.createSurface() catch @panic("Failed to create surface");

                    const layer_surface = seto.layer_shell.?.getLayerSurface(
                        surface,
                        wl_output,
                        .overlay,
                        "seto",
                    ) catch @panic("Failed to get layer surface");
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

                    seto.outputs.append(output) catch @panic("OOM");

                    xdg_output.setListener(*Seto, xdgOutputListener, seto);
                    layer_surface.setListener(*Seto, layerSurfaceListener, seto);
                    wl_output.setListener(*Seto, wlOutputListener, seto);
                },
                .wl_seat => {
                    const wl_seat = registry.bind(
                        global.name,
                        wl.Seat,
                        wl.Seat.generated_version,
                    ) catch @panic("Failed to bind seat global");
                    wl_seat.setListener(*Seto, seatListener, seto);
                    seto.seat.wl_seat = wl_seat;
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

                    var outputs_info = seto.alloc.alloc(OutputInfo, seto.outputs.items.len) catch @panic("");
                    defer seto.alloc.free(outputs_info);
                    for (seto.outputs.items, 0..) |o, j| {
                        outputs_info[j] = o.info;
                    }

                    seto.state.total_dimensions = TotalDimensions.updateDimensions(outputs_info);
                    return;
                }
            }
        },
    }
}

test "single monitor" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{.{ .id = 1, .name = try allocator.dupe(u8, "Single"), .width = 1920, .height = 1080, .x = 0, .y = 0 }};

    const dimensions = TotalDimensions.updateDimensions(&outputs);
    defer outputs[0].deinit(allocator);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1079), dimensions.height);
}

test "your specific monitor layout" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{
            .id = 1,
            .name = try allocator.dupe(u8, "HDMI-A-7"),
            .width = 1920,
            .height = 1080,
            .x = 960,
            .y = 0,
        },
        .{
            .id = 2,
            .name = try allocator.dupe(u8, "DP-4"),
            .width = 1920,
            .height = 1080,
            .x = 0,
            .y = 1080,
        },
        .{
            .id = 3,
            .name = try allocator.dupe(u8, "DP-5"),
            .width = 1920,
            .height = 1080,
            .x = 1920,
            .y = 1080,
        },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 1080), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1920 + 1920 - 1 - 0), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1080 + 1080 - 1 - 1080), dimensions.height);
}

test "vertical stack" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{ .{ .id = 1, .name = try allocator.dupe(u8, "Top"), .width = 1920, .height = 1080, .x = 0, .y = 0 }, .{ .id = 2, .name = try allocator.dupe(u8, "Bottom"), .width = 1920, .height = 1080, .x = 0, .y = 1080 } };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 1919), dimensions.width);
    try std.testing.expectEqual(@as(f32, 2159), dimensions.height);
}

test "ignore zero-sized monitors" {
    const allocator = std.testing.allocator;

    var outputs = [_]OutputInfo{
        .{ .id = 1, .name = try allocator.dupe(u8, "Active"), .width = 2560, .height = 1440, .x = 0, .y = 0 },
        .{
            .id = 2,
            .name = try allocator.dupe(u8, "Inactive"),
            .width = 0,
            .height = 0,
            .x = 2560,
            .y = 0,
        },
    };
    defer {
        for (&outputs) |*out| out.deinit(allocator);
    }

    const dimensions = TotalDimensions.updateDimensions(&outputs);

    try std.testing.expectEqual(@as(f32, 0), dimensions.x);
    try std.testing.expectEqual(@as(f32, 0), dimensions.y);
    try std.testing.expectEqual(@as(f32, 2559), dimensions.width);
    try std.testing.expectEqual(@as(f32, 1439), dimensions.height);
}
