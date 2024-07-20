const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const c = @import("ffi");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const Tree = @import("Tree.zig");
const OutputInfo = @import("surface.zig").OutputInfo;
const Surface = @import("surface.zig").Surface;
const SurfaceIterator = @import("surface.zig").SurfaceIterator;
const Seat = @import("seat.zig").Seat;
const Config = @import("Config.zig");
const Egl = @import("Egl.zig");

const handleKey = @import("seat.zig").handleKey;
const xdgOutputListener = @import("surface.zig").xdgOutputListener;
const layerSurfaceListener = @import("surface.zig").layerSurfaceListener;
const seatListener = @import("seat.zig").seatListener;
const parseArgs = @import("cli.zig").parseArgs;
const inPlaceReplace = @import("helpers").inPlaceReplace;

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
    outputs: std.ArrayList(Surface),
    config: Config,
    alloc: mem.Allocator,
    tree: ?Tree = null,
    total_dimensions: [2]i32 = .{ 0, 0 },
    state: State = State{},

    const Self = @This();

    fn new(alloc: mem.Allocator, display: *wl.Display) !Self {
        var seto = Seto{
            .seat = Seat.new(alloc),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
            .egl = try Egl.new(display),
            .config = Config.load(alloc),
        };

        parseArgs(&seto);
        seto.config.keys.loadTextures(&seto.config.font);
        return seto;
    }

    pub fn updateDimensions(self: *Self) void {
        // Sort outputs from left to right row by row
        std.mem.sort(Surface, self.outputs.items, self.outputs.items[0], Surface.cmp);

        const first = self.outputs.items[0].output_info;
        const last = self.outputs.getLast().output_info;

        self.total_dimensions = .{ (last.x + last.width) - first.x, (last.y + last.height) - first.y };
    }

    fn formatOutput(self: *Self, arena: *std.heap.ArenaAllocator, top_left: [2]i32, size: [2]i32) void {
        var surf_iter = SurfaceIterator.new(&self.outputs.items);
        while (surf_iter.next()) |surface| {
            if (!surface.isConfigured()) continue;

            const info = surface.output_info;

            if (surface.posInSurface(top_left)) {
                const relative_pos = .{ top_left[0] - info.x, top_left[1] - info.y };
                const relative_size = .{
                    @abs(top_left[0] - @min((info.x + info.width), top_left[0] + size[0])),
                    @abs(top_left[1] - @min((info.y + info.height), top_left[1] + size[1])),
                };

                const output_name = if (info.name) |name| name else "<unkown>";

                inPlaceReplace([]const u8, arena.allocator(), &self.config.output_format, "%o", output_name);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%X", relative_pos[0]);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%Y", relative_pos[1]);
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%W", relative_size[0]);
                inPlaceReplace(u32, arena.allocator(), &self.config.output_format, "%H", relative_size[1]);

                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%x", top_left[0]);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%y", top_left[1]);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%w", size[0]);
                inPlaceReplace(i32, arena.allocator(), &self.config.output_format, "%h", size[1]);

                return;
            }
        }
    }

    fn printToStdout(self: *Self) !void {
        const coords = try self.tree.?.find(&self.seat.buffer.items);
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();

        switch (self.state.mode) {
            .Single => self.formatOutput(&arena, coords, .{ 1, 1 }),
            .Region => |positions| if (positions) |pos| {
                const top_left: [2]i32 = .{ @min(coords[0], pos[0]), @min(coords[1], pos[1]) };
                const bottom_right: [2]i32 = .{ @max(coords[0], pos[0]), @max(coords[1], pos[1]) };

                const width = bottom_right[0] - top_left[0];
                const height = bottom_right[1] - top_left[1];

                const size: [2]i32 = .{ if (width == 0) 1 else width, if (height == 0) 1 else height };

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

    fn render(self: *Self) !void {
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

        var surf_iter = SurfaceIterator.new(&self.outputs.items);
        while (surf_iter.next()) |surface| {
            if (!surface.isConfigured()) continue;
            surface.egl.makeCurrent() catch @panic("Failed to attach egl rendering context to EGL surface");

            c.glClear(c.GL_COLOR_BUFFER_BIT);
            c.glUseProgram(self.egl.main_shader_program);

            surface.draw(self.state.border_mode, self.state.mode);

            c.glUseProgram(self.egl.text_shader_program);
            self.tree.?.drawText(surface, self.seat.buffer.items, self.state.border_mode);
            surface.egl.swapBuffers() catch @panic("Failed to post EGL surface color buffer to a native window ");
        }
    }

    fn shouldDraw(self: *Self) bool {
        defer self.state.first_draw = false;
        return self.seat.repeat.key != null or self.state.first_draw;
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
        self.egl.destroy();
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

    registry.setListener(*Seto, registryListener, &seto);
    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;

    if (seto.compositor == null or seto.layer_shell == null) @panic("Compositor or layer shell not bound");

    while (display.dispatch() == .SUCCESS and !seto.state.exit) {
        if (seto.seat.repeatKey()) handleKey(&seto);
        try seto.render();
    }

    var surf_iter = SurfaceIterator.new(&seto.outputs.items);
    while (surf_iter.next()) |surface| {
        surface.egl.makeCurrent() catch @panic("Failed to attach egl rendering context to EGL surface");
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        surface.egl.swapBuffers() catch @panic("Failed to post EGL surface color buffer to a native window ");
    }

    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;
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
                    ) catch @panic("Failed to bind compositor global");
                },
                .zwlr_layer_shell_v1 => {
                    seto.layer_shell = registry.bind(
                        global.name,
                        zwlr.LayerShellV1,
                        zwlr.LayerShellV1.generated_version,
                    ) catch @panic("Failed to bind layer shell global");
                },
                .wl_output => {
                    const global_output = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch @panic("Failed to bind output global");

                    const surface = seto.compositor.?.createSurface() catch @panic("Failed to create surface");

                    const layer_surface = seto.layer_shell.?.getLayerSurface(
                        surface,
                        global_output,
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

                    const xdg_output = seto.output_manager.?.getXdgOutput(global_output) catch @panic("Failed to get xdg output global");

                    const egl_surface = seto.egl.newSurface(surface, .{ 1, 1 }) catch @panic("Failed to create egl surface");

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
                if (output.output_info.id == global.name) {
                    output.destroy();
                    _ = seto.outputs.swapRemove(i);
                    seto.updateDimensions();
                    return;
                }
            }
        },
    }
}
