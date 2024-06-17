const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const wayland = @import("wayland");
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;
const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("EGL/egl.h");

    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("GL/gl.h");
    @cInclude("GL/glext.h");

    @cInclude("sys/epoll.h");
});

const Seto = @import("main.zig").Seto;
const Config = @import("config.zig").Config;
const Tree = @import("tree.zig").Tree;
const EglSurface = @import("egl.zig").EglSurface;

pub const OutputInfo = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    height: i32 = 0,
    width: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    wl_output: *wl.Output,

    const Self = @This();

    fn destroy(self: *Self, alloc: mem.Allocator) void {
        self.wl_output.destroy();
        alloc.free(self.name.?);
        alloc.free(self.description.?);
    }
};

pub const Surface = struct {
    egl: EglSurface,
    layer_surface: *zwlr.LayerSurfaceV1,
    surface: *wl.Surface,
    alloc: mem.Allocator,
    output_info: OutputInfo,
    xdg_output: *zxdg.OutputV1,
    config: *const Config,

    const Self = @This();

    pub fn new(
        egl: EglSurface,
        surface: *wl.Surface,
        layer_surface: *zwlr.LayerSurfaceV1,
        alloc: mem.Allocator,
        xdg_output: *zxdg.OutputV1,
        output_info: OutputInfo,
        config_ptr: *Config,
    ) Self {
        return .{
            .config = config_ptr,
            .egl = egl,
            .surface = surface,
            .layer_surface = layer_surface,
            .alloc = alloc,
            .output_info = output_info,
            .xdg_output = xdg_output,
        };
    }

    pub fn posInSurface(self: Self, coordinates: [2]i32) bool {
        const info = self.output_info;
        return coordinates[0] < info.x + info.width and coordinates[0] >= info.x and coordinates[1] < info.y + info.height and coordinates[1] >= info.y;
    }

    pub fn cmp(_: Self, a: Self, b: Self) bool {
        if (a.output_info.x != b.output_info.x)
            return a.output_info.x < b.output_info.x
        else
            return a.output_info.y < b.output_info.y;
    }

    pub fn draw(self: *Self) void {
        const info = self.output_info;
        const grid = self.config.grid;

        c.glLineWidth(self.config.grid.line_width);

        // var vertices = std.ArrayList(f32).init(self.alloc);
        // defer vertices.deinit();

        const width: f32 = @floatFromInt(info.width);
        const height: f32 = @floatFromInt(info.height);

        var i: i32 = grid.offset[0];
        while (i <= info.width) : (i += grid.size[0]) {
            // vertices.append(2 * (@as(f32, @floatFromInt(i)) / width) - 1) catch @panic("OOM");
            // vertices.append(1) catch @panic("OOM");
            // vertices.append(2 * (@as(f32, @floatFromInt(i)) / width) - 1) catch @panic("OOM");
            // vertices.append(-1) catch @panic("OOM");
            const vertices = [_]f32{
                2 * (@as(f32, @floatFromInt(i)) / width) - 1, 1,
                2 * (@as(f32, @floatFromInt(i)) / width) - 1, -1,
            };

            c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&vertices));
            c.glEnableVertexAttribArray(0);

            c.glDrawArrays(c.GL_LINES, 0, 2);
        }

        i = grid.offset[1];
        while (i <= info.height) : (i += grid.size[1]) {
            //     vertices.append(-1) catch @panic("OOM");
            //     vertices.append(2 * (@as(f32, @floatFromInt(i)) / height) - 1) catch @panic("OOM");
            //     vertices.append(1) catch @panic("OOM");
            //     vertices.append(2 * (@as(f32, @floatFromInt(i)) / height) - 1) catch @panic("OOM");
            const vertices = [_]f32{
                -1, 2 * ((height - @as(f32, @floatFromInt(i))) / height) - 1,
                1,  2 * ((height - @as(f32, @floatFromInt(i))) / height) - 1,
            };

            c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&vertices));
            c.glEnableVertexAttribArray(0);

            c.glDrawArrays(c.GL_LINES, 0, 2);
        }

        // c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&vertices));
        // c.glEnableVertexAttribArray(0);

        // c.glDrawArrays(c.GL_LINES, 0, 100);
    }

    pub fn isConfigured(self: *const Self) bool {
        return self.output_info.width > 0 and self.output_info.height > 0;
    }

    pub fn destroy(self: *Self) void {
        self.layer_surface.destroy();
        self.surface.destroy();
        self.output_info.destroy(self.alloc);
        self.xdg_output.destroy();
    }
};

pub const SurfaceIterator = struct {
    position: [2]i32 = .{ 0, 0 },
    outputs: []Surface,
    index: u8 = 0,

    const Self = @This();

    pub fn new(outputs: []Surface) Self {
        return Self{ .outputs = outputs };
    }

    fn isNewline(self: *Self) bool {
        return self.index > 0 and self.outputs[self.index].output_info.x <= self.outputs[self.index - 1].output_info.x;
    }

    pub fn next(self: *Self) ?std.meta.Tuple(&.{ Surface, [2]i32 }) {
        if (self.index >= self.outputs.len) return null;
        const output = self.outputs[self.index];
        if (!output.isConfigured()) return self.next();

        if (self.isNewline()) {
            self.position = .{ 0, self.outputs[self.index - 1].output_info.height };
        }

        defer self.index += 1;
        defer self.position[0] += output.output_info.width;

        return .{ output, self.position };
    }
};

pub fn frameListener(callback: *wl.Callback, event: wl.Callback.Event, surface: *Surface) void {
    defer callback.destroy();
    if (event == .done) surface.draw() catch return;
}

pub fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
        .configure => |configure| {
            for (seto.outputs.items) |*surface| {
                if (surface.layer_surface == lsurf) {
                    surface.layer_surface.setSize(configure.width, configure.height);
                    surface.layer_surface.ackConfigure(configure.serial);
                    surface.egl.resize(.{ configure.width, configure.height });
                }
            }
        },
        .closed => {},
    }
}

pub fn xdgOutputListener(
    output: *zxdg.OutputV1,
    event: zxdg.OutputV1.Event,
    seto: *Seto,
) void {
    for (seto.outputs.items) |*surface| {
        if (surface.xdg_output == output) {
            switch (event) {
                .name => |e| {
                    surface.output_info.name = seto.alloc.dupe(u8, mem.span(e.name)) catch @panic("OOM");
                },
                .description => |e| {
                    surface.output_info.description = seto.alloc.dupe(u8, mem.span(e.description)) catch @panic("OOM");
                },
                .logical_position => |pos| {
                    surface.output_info.x = pos.x;
                    surface.output_info.y = pos.y;
                },
                .logical_size => |size| {
                    surface.output_info.height = size.height;
                    surface.output_info.width = size.width;

                    seto.updateDimensions();
                    seto.sortOutputs();

                    if (seto.tree) |tree| tree.arena.deinit();
                    seto.tree = Tree.new(
                        seto.config.keys.search,
                        seto.alloc,
                        seto.total_dimensions,
                        seto.config.grid,
                        seto.outputs.items,
                    );
                },
                .done => {},
            }
        }
    }
}
