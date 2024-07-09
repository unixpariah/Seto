const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;
const wayland = @import("wayland");
const c = @import("ffi");

const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;
const Config = @import("Config.zig");
const EglSurface = @import("Egl.zig").EglSurface;
const Tree = @import("Tree.zig");
const Color = @import("helpers").Color;

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

    fn drawBackground(self: *Self, VBO: u32) void {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);

        setColor(self.config.background_color, self.egl.shader_program.*);

        const info = self.output_info;
        const bg_vertices = [_]i32{
            info.x,              info.y,
            info.x + info.width, info.y,
            info.x + info.width, info.y + info.height,

            info.x + info.width, info.y + info.height,
            info.x,              info.y + info.height,
            info.x,              info.y,
        };

        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * bg_vertices.len, &bg_vertices, c.GL_STATIC_DRAW);
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(bg_vertices.len >> 1));
    }

    fn drawSelection(self: *Self, mode: Mode, VBO: u32) void {
        if (mode.Region) |pos| {
            c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);

            const info = self.output_info;

            var selected_vertices: [8]i32 =
                if (mode.withinBounds(&info)) .{
                pos[0],              info.y,
                pos[0],              info.y + info.height,
                info.x,              pos[1],
                info.x + info.width, pos[1],
            } else if (mode.horWithinBounds(&info)) .{
                info.x,              pos[1],
                info.x + info.width, pos[1],
                0,                   0,
                0,                   0,
            } else if (mode.verWithinBounds(&info)) .{
                pos[0], info.y,
                pos[0], info.y + info.height,
                0,      0,
                0,      0,
            } else unreachable;

            setColor(self.config.grid.selected_color, self.egl.shader_program.*);

            c.glLineWidth(self.config.grid.selected_line_width);
            c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * selected_vertices.len, &selected_vertices, c.GL_STATIC_DRAW);
            c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
            c.glDrawArrays(c.GL_LINES, 0, @intCast(selected_vertices.len >> 1));
        }
    }

    fn drawGrid(self: *Self, border_mode: bool, start_pos: [2]?i32, VBO: u32) [2]?i32 {
        const info = self.output_info;
        const grid = self.config.grid;

        c.glLineWidth(grid.line_width);
        setColor(grid.color, self.egl.shader_program.*);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);

        if (border_mode) {
            const vertices = [_]i32{
                info.x,              info.y,
                info.x + info.width, info.y,
                info.x + info.width, info.y + info.height,
                info.x,              info.y + info.height,
            };

            c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
            c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
            c.glDrawArrays(c.GL_LINE_LOOP, 0, vertices.len >> 1);

            return .{ null, null };
        }

        var vertices = std.ArrayList(i32).init(self.alloc);
        defer vertices.deinit();

        var pos_x = start_pos[0] orelse grid.offset[0];
        while (pos_x <= info.x + info.width) : (pos_x += grid.size[0]) {
            vertices.appendSlice(&[_]i32{
                pos_x, info.y,
                pos_x, info.y + info.height,
            }) catch @panic("OOM");
        }

        var pos_y = start_pos[1] orelse grid.offset[1];
        while (pos_y <= info.y + info.height) : (pos_y += grid.size[1]) {
            vertices.appendSlice(&[_]i32{
                info.x,              info.y + info.height - pos_y,
                info.x + info.width, info.y + info.height - pos_y,
            }) catch @panic("OOM");
        }

        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            @intCast(@sizeOf(i32) * vertices.items.len),
            @ptrCast(vertices.items),
            c.GL_STATIC_DRAW,
        );
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawArrays(c.GL_LINES, 0, @intCast(vertices.items.len >> 1));

        return .{ pos_x, pos_y };
    }

    pub fn draw(self: *Self, start_pos: [2]?i32, border_mode: bool, mode: Mode) [2]?i32 {
        self.egl.makeCurrent() catch {
            std.log.err("Failed to make current\n", .{});
            std.process.exit(1);
        };
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        var VAO: u32 = undefined;
        c.glGenVertexArrays(1, &VAO);
        defer c.glDeleteVertexArrays(1, &VAO);

        c.glBindVertexArray(VAO);
        defer c.glBindVertexArray(0);

        var VBO: u32 = undefined;
        c.glGenBuffers(1, &VBO);
        defer c.glDeleteBuffers(1, &VBO);

        const info = self.output_info;
        c.glUniform4f(
            c.glGetUniformLocation(self.egl.shader_program.*, "u_surface"),
            @floatFromInt(info.x),
            @floatFromInt(info.y),
            @floatFromInt(info.x + info.width),
            @floatFromInt(info.y + info.height),
        );

        c.glEnableVertexAttribArray(0);

        defer if (mode == .Region) self.drawSelection(mode, VBO);
        self.drawBackground(VBO);
        //self.renderText("asdfghjkl", 500, 500, VBO);
        return self.drawGrid(border_mode, start_pos, VBO);
    }

    pub fn renderText(self: *Self, text: []const u8, x: i32, y: i32, VBO: u32) void {
        setColor(self.config.font.color, self.egl.shader_program.*);
        c.glActiveTexture(c.GL_TEXTURE0);

        for (text, 0..) |char, i| {
            const ch = self.config.keys.char_info.get(char).?;

            const move: i32 = @intCast(ch.advance[0] * i);

            const x_pos = x + ch.bearing[0] + move;
            const y_pos = y + (ch.size[1] - ch.bearing[1]);

            const vertices = [_][4]i32{
                .{ x_pos, y_pos + ch.size[1], 0, 0 },
                .{ x_pos, y_pos, 0, 1 },
                .{ x_pos + ch.size[0], y_pos, 1, 1 },

                .{ x_pos, y_pos + ch.size[1], 0, 0 },
                .{ x_pos + ch.size[0], y_pos, 1, 1 },
                .{ x_pos + ch.size[0], y_pos + ch.size[1], 1, 0 },
            };

            c.glBindTexture(c.GL_TEXTURE_2D, ch.texture_id);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
            c.glBufferSubData(c.GL_ARRAY_BUFFER, 0, @sizeOf(i32) * vertices.len * vertices[0].len, &vertices);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
            c.glDrawArrays(c.GL_TRIANGLES, 0, vertices.len);
        }
    }

    pub fn isConfigured(self: *const Self) bool {
        return self.output_info.width > 0 and self.output_info.height > 0;
    }

    pub fn destroy(self: *Self) void {
        self.layer_surface.destroy();
        self.surface.destroy();
        self.output_info.destroy(self.alloc);
        self.xdg_output.destroy();
        self.egl.destroy();
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

pub fn setColor(color: Color, shader_program: c_uint) void {
    c.glUniform4f(
        c.glGetUniformLocation(shader_program, "u_startcolor"),
        color.start_color[0] * color.start_color[3],
        color.start_color[1] * color.start_color[3],
        color.start_color[2] * color.start_color[3],
        color.start_color[3],
    );
    c.glUniform4f(
        c.glGetUniformLocation(shader_program, "u_endcolor"),
        color.end_color[0] * color.end_color[3],
        color.end_color[1] * color.end_color[3],
        color.end_color[2] * color.end_color[3],
        color.end_color[3],
    );
    c.glUniform1f(c.glGetUniformLocation(shader_program, "u_degrees"), color.deg);
}
