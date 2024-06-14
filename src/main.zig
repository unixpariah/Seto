const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const cairo = @import("cairo");
const pango = @import("pango");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;
const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("GLES2/gl2.h");
    @cInclude("EGL/egl.h");
});

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
const frameListener = @import("surface.zig").frameListener;

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

pub const Seto = struct {
    compositor: ?*wl.Compositor = null,
    layer_shell: ?*zwlr.LayerShellV1 = null,
    output_manager: ?*zxdg.OutputManagerV1 = null,
    seat: Seat,
    outputs: std.ArrayList(Surface),
    config: Config,
    alloc: mem.Allocator,
    tree: ?Tree = null,
    total_dimensions: [2]i32 = .{ 0, 0 },
    egl: Egl,

    first_draw: bool = true,
    exit: bool = false,
    mode: Mode = .Single,
    border_mode: bool = false,

    const Self = @This();

    fn new(alloc: mem.Allocator, display: *wl.Display) Self {
        return .{
            .seat = Seat.new(alloc),
            .outputs = std.ArrayList(Surface).init(alloc),
            .alloc = alloc,
            .config = Config.load(alloc),
            .egl = Egl.new(display) catch unreachable,
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

    fn drawGrid(self: *Self, width: u32, height: u32, context: *cairo.Context) void {
        const grid = self.config.grid;

        defer switch (self.mode) {
            .Region => |position| if (position) |pos| {
                context.moveTo(0, @floatFromInt(pos[1]));
                context.lineTo(@floatFromInt(width), @floatFromInt(pos[1]));

                context.moveTo(@floatFromInt(pos[0]), 0);
                context.lineTo(@floatFromInt(pos[0]), @floatFromInt(height));

                context.setSourceRgba(grid.selected_color[0], grid.selected_color[1], grid.selected_color[2], grid.selected_color[3]);
                context.setLineWidth(grid.selected_line_width);
                context.stroke();
            },
            .Single => {},
        };

        if (self.border_mode) {
            var surf_iter = SurfaceIterator.new(self.outputs.items);
            while (surf_iter.next()) |res| {
                const surface: Surface, const pos: [2]i32 = res;
                const info = surface.output_info;

                context.rectangle(.{
                    .x = @floatFromInt(pos[0]),
                    .y = @floatFromInt(pos[1]),
                    .width = @floatFromInt(info.width),
                    .height = @floatFromInt(info.height),
                });
            }

            context.setSourceRgba(grid.color[0], grid.color[1], grid.color[2], grid.color[3]);
            context.setLineWidth(grid.line_width);
            context.stroke();

            return;
        }

        var i: i32 = grid.offset[0];
        while (i <= width) : (i += grid.size[0]) {
            context.moveTo(@floatFromInt(i), 0);
            context.lineTo(@floatFromInt(i), @floatFromInt(height));
        }

        i = grid.offset[1];
        while (i <= height) : (i += grid.size[1]) {
            context.moveTo(0, @floatFromInt(i));
            context.lineTo(@floatFromInt(width), @floatFromInt(i));
        }

        context.setSourceRgba(grid.color[0], grid.color[1], grid.color[2], grid.color[3]);
        context.setLineWidth(grid.line_width);
        context.stroke();
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

    fn createLayout(self: *Self, ctx: *cairo.Context) *pango.Layout {
        const font = self.config.font;
        const layout: *pango.Layout = ctx.createLayout() catch @panic("OOM");
        const font_description = pango.FontDescription.new() catch @panic("OOM");
        defer font_description.free();

        font_description.setFamilyStatic(font.family);
        font_description.setStyle(font.style);
        font_description.setWeight(font.weight);
        font_description.setAbsoluteSize(font.size * pango.SCALE);
        font_description.setVariant(font.variant);
        font_description.setStretch(font.stretch);
        font_description.setGravity(font.gravity);

        layout.setFontDescription(font_description);

        ctx.setSourceRgba(font.color[0], font.color[1], font.color[2], font.color[3]);

        return layout;
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

        const cairo_surface = try cairo.ImageSurface.create(.argb32, @intCast(self.total_dimensions[0]), @intCast(self.total_dimensions[1]));
        defer cairo_surface.destroy();
        const ctx = try cairo.Context.create(cairo_surface.asSurface());
        defer ctx.destroy();

        const bg_color = self.config.background_color;
        ctx.setSourceRgba(bg_color[0], bg_color[1], bg_color[2], bg_color[3]);
        ctx.paint();

        self.drawGrid(@intCast(self.total_dimensions[0]), @intCast(self.total_dimensions[1]), ctx);
        const layout = self.createLayout(ctx);
        defer layout.destroy();

        self.tree.?.drawText(
            ctx,
            self.config.font,
            self.seat.buffer.items,
            layout,
            self.border_mode,
            self.outputs.items,
        );

        var surf_iter = SurfaceIterator.new(self.outputs.items);
        while (surf_iter.next()) |res| {
            const surface: Surface, const pos: [2]i32 = res;
            const info = surface.output_info;

            const output_surface = try cairo.ImageSurface.create(.argb32, @intCast(info.width), @intCast(info.height));
            defer output_surface.destroy();
            const output_ctx = try cairo.Context.create(output_surface.asSurface());
            defer output_ctx.destroy();

            output_ctx.setSourceSurface(cairo_surface.asSurface(), @floatFromInt(-pos[0]), @floatFromInt(-pos[1]));
            output_ctx.paint();

            const data = try output_surface.getData();
            _ = data;
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

    var seto = Seto.new(alloc, display);
    defer seto.destroy();

    parseArgs(&seto);

    registry.setListener(*Seto, registryListener, &seto);
    if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
    if (display.roundtrip() != .SUCCESS) return error.DispatchFailed;

    if (seto.compositor == null or seto.layer_shell == null) {
        std.debug.print("Compositor, layer_shell or shm not bound", .{});
        std.process.exit(1);
    }

    while (display.dispatch() == .SUCCESS and !seto.exit) {
        if (seto.seat.repeatKey()) handleKey(&seto);
        try seto.createSurfaces();
    }

    if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
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

                    const output_info = OutputInfo{ .wl_output = global_output };
                    const output = Surface.new(surface, layer_surface, seto.alloc, xdg_output, output_info);

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
        .global_remove => {},
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
