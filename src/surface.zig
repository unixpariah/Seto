const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;
const wayland = @import("wayland");
const c = @import("ffi.zig");

const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;
const Config = @import("Config.zig");
const EglSurface = @import("Egl.zig").EglSurface;
const Tree = @import("Tree.zig");

pub const OutputInfo = struct {
    id: u32,
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    height: i32 = 0,
    width: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,

    const Self = @This();

    fn destroy(self: *Self, alloc: mem.Allocator) void {
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

    fn drawBackground(self: *Self) void {
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        self.egl.makeCurrent() catch unreachable;

        const bg = self.config.background_color;
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_startcolor"),
            bg.start_color[0] * bg.start_color[3],
            bg.start_color[1] * bg.start_color[3],
            bg.start_color[2] * bg.start_color[3],
            bg.start_color[3],
        );
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_endcolor"),
            bg.end_color[0] * bg.end_color[3],
            bg.end_color[1] * bg.end_color[3],
            bg.end_color[2] * bg.end_color[3],
            bg.end_color[3],
        );
        c.glUniform1f(c.glGetUniformLocation(self.egl.shader_program.*, "u_degrees"), bg.deg);

        const bg_vertices = [_]f32{
            1, 1,
            1, 0,
            0, 0,
            0, 1,
        };

        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&bg_vertices));
        c.glDrawArrays(c.GL_POLYGON, 0, @intCast(bg_vertices.len >> 1));
    }

    fn drawSelection(self: *Self, mode: Mode) void {
        if (mode.Region) |pos| {
            const info = self.output_info;
            const width: f32 = @floatFromInt(info.width);
            const height: f32 = @floatFromInt(info.height);

            const f_position: [2]f32 = .{ @floatFromInt(pos[0]), @floatFromInt(pos[1]) };
            const f_p: [2]f32 = .{ @floatFromInt(info.x), @floatFromInt(info.y) };

            var selected_vertices: [8]f32 =
                if (mode.withinBounds(&info)) .{
                (f_position[0] - f_p[0]) / width, 0,
                (f_position[0] - f_p[0]) / width, 1,
                0,                                (f_position[1] - f_p[1]) / height,
                1,                                (f_position[1] - f_p[1]) / height,
            } else if (mode.horWithinBounds(&info)) .{
                0, (f_position[1] - f_p[1]) / height,
                1, (f_position[1] - f_p[1]) / height,
                0, 0,
                0, 0,
            } else if (mode.verWithinBounds(&info)) .{
                (f_position[0] - f_p[0]) / width, 0,
                (f_position[0] - f_p[0]) / width, 1,
                0,                                0,
                0,                                0,
            } else unreachable;

            const selected_color = self.config.grid.selected_color;
            c.glUniform4f(
                c.glGetUniformLocation(self.egl.shader_program.*, "u_startcolor"),
                selected_color.start_color[0] * selected_color.start_color[3],
                selected_color.start_color[1] * selected_color.start_color[3],
                selected_color.start_color[2] * selected_color.start_color[3],
                selected_color.start_color[3],
            );
            c.glUniform4f(
                c.glGetUniformLocation(self.egl.shader_program.*, "u_endcolor"),
                selected_color.end_color[0] * selected_color.end_color[3],
                selected_color.end_color[1] * selected_color.end_color[3],
                selected_color.end_color[2] * selected_color.end_color[3],
                selected_color.end_color[3],
            );
            c.glUniform1f(c.glGetUniformLocation(self.egl.shader_program.*, "u_degrees"), selected_color.deg);
            c.glLineWidth(self.config.grid.selected_line_width);

            c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&selected_vertices));
            c.glDrawArrays(c.GL_LINES, 0, @intCast(selected_vertices.len >> 1));
        }
    }

    pub fn draw(self: *Self, start_pos: [2]?i32, border_mode: bool, mode: Mode) [2]?i32 {
        self.drawBackground();

        const color = self.config.grid.color;
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_startcolor"),
            color.start_color[0] * color.start_color[3],
            color.start_color[1] * color.start_color[3],
            color.start_color[2] * color.start_color[3],
            color.start_color[3],
        );
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_endcolor"),
            color.end_color[0] * color.end_color[3],
            color.end_color[1] * color.end_color[3],
            color.end_color[2] * color.end_color[3],
            color.end_color[3],
        );
        c.glUniform1f(c.glGetUniformLocation(self.egl.shader_program.*, "u_degrees"), color.deg);

        var vertices = std.ArrayList(f32).init(self.alloc);
        defer vertices.deinit();

        const grid = self.config.grid;
        c.glLineWidth(grid.line_width);

        defer if (mode == .Region) self.drawSelection(mode);

        if (border_mode) {
            vertices.appendSlice(&[_]f32{
                1, 1,
                1, 0,
                0, 0,
                0, 1,
            }) catch @panic("OOM");

            c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(vertices.items));
            c.glDrawArrays(c.GL_LINE_LOOP, 0, @intCast(vertices.items.len >> 1));

            return .{ null, null };
        }

        const info = self.output_info;
        const width: f32 = @floatFromInt(info.width);
        const height: f32 = @floatFromInt(info.height);

        var pos_x = if (start_pos[0]) |pos| pos else grid.offset[0];
        while (pos_x <= info.width) : (pos_x += grid.size[0]) {
            vertices.appendSlice(&[_]f32{
                @as(f32, @floatFromInt(pos_x)) / width, 0,
                @as(f32, @floatFromInt(pos_x)) / width, 1,
            }) catch @panic("OOM");
        }

        var pos_y = if (start_pos[1]) |pos| pos else grid.offset[1];
        while (pos_y <= info.height) : (pos_y += grid.size[1]) {
            vertices.appendSlice(&[_]f32{
                0, (height - @as(f32, @floatFromInt(pos_y))) / height,
                1, (height - @as(f32, @floatFromInt(pos_y))) / height,
            }) catch @panic("OOM");
        }

        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(vertices.items));
        c.glDrawArrays(c.GL_LINES, 0, @intCast(vertices.items.len >> 1));

        self.renderText("asdfghjkl", 1000, 0);

        return .{ pos_x - info.width, pos_y - info.height };
    }

    pub fn renderText(self: *Self, text: []const u8, x: f32, y: f32) void {
        const info = self.output_info;

        const width: f32 = @floatFromInt(info.width);
        const height: f32 = @floatFromInt(info.height);

        const x_norm = x / width;
        const y_norm = y / height;

        c.glActiveTexture(c.GL_TEXTURE0);

        const color = self.config.font.color;
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_startcolor"),
            color.start_color[0],
            color.start_color[1],
            color.start_color[2],
            color.start_color[3],
        );
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_endcolor"),
            color.end_color[0],
            color.end_color[1],
            color.end_color[2],
            color.end_color[3],
        );
        c.glUniform1f(c.glGetUniformLocation(self.egl.shader_program.*, "u_degrees"), color.deg);

        for (text, 0..) |char, i| {
            const ch = self.config.keys.char_info.get(char).?;

            const size = .{
                ch.size[0] / width,
                ch.size[1] / height,
            };
            const bearing = .{
                ch.bearing[0] / width,
                ch.bearing[1] / height,
            };
            const advance = .{
                ch.advance[0] / width / 64,
                ch.advance[1] / height / 64,
            };

            const move = advance[0] * @as(f32, @floatFromInt(i));

            const x_pos = x_norm + bearing[0] + move;
            const y_pos = y_norm + (size[1] - bearing[1]);

            const vertices = [_]f32{
                x_pos,           y_pos,
                x_pos + size[0], y_pos,
                x_pos + size[0], y_pos + size[1],

                x_pos,           y_pos,
                x_pos,           y_pos + size[1],
                x_pos + size[0], y_pos + size[1],
            };

            c.glBindTexture(c.GL_TEXTURE_2D, ch.texture_id);
            c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, @ptrCast(&vertices));
            c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(vertices.len >> 1));
        }
    }

    pub fn isConfigured(self: *const Self) bool {
        return self.output_info.width > 0 and self.output_info.height > 0;
    }

    pub fn destroy(self: *Self) !void {
        self.layer_surface.destroy();
        self.surface.destroy();
        self.output_info.destroy(self.alloc);
        self.xdg_output.destroy();
        try self.egl.destroy();
    }
};

pub const SurfaceIterator = struct {
    position: [2]i32,
    outputs: *const []Surface,
    index: u8 = 0,

    const Self = @This();

    pub fn new(outputs: *const []Surface) Self {
        return Self{ .outputs = outputs, .position = .{ outputs.*[0].output_info.x, outputs.*[0].output_info.y } };
    }

    fn isNewline(self: *Self) bool {
        if (self.index == 0) return false;
        return self.outputs.*[self.index].output_info.x <= self.outputs.*[self.index - 1].output_info.x;
    }

    pub fn next(self: *Self) ?std.meta.Tuple(&.{ Surface, [2]i32, bool }) {
        if (self.index >= self.outputs.len or !self.outputs.*[self.index].isConfigured()) return null;
        const output = self.outputs.*[self.index];

        if (self.isNewline()) {
            self.position = .{ 0, self.outputs.*[self.index - 1].output_info.height };
        }

        defer self.index += 1;
        defer self.position[0] += output.output_info.width;

        return .{ output, self.position, self.isNewline() };
    }
};

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

                    if (seto.tree) |tree| tree.arena.deinit();
                    seto.tree = Tree.new(
                        seto.config.keys.search,
                        seto.alloc,
                        &seto.config.grid,
                        &seto.outputs.items,
                    );
                },
                .done => {},
            }
        }
    }
}
