const std = @import("std");
const wayland = @import("wayland");
const c = @import("ffi");
const helpers = @import("helpers");
const math = @import("math");

const mem = std.mem;
const posix = std.posix;
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;

const mul = math.mul;
const translate = math.translate;

const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;
const Config = @import("Config.zig");
const EglSurface = @import("Egl.zig").EglSurface;
const Tree = @import("Tree.zig");
const Color = helpers.Color;

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

    config: *Config,

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

    fn posInY(self: *const Self, coordinates: [2]i32) bool {
        const info = self.output_info;
        return coordinates[1] < info.y + info.height and coordinates[1] >= info.y;
    }

    fn posInX(self: *const Self, coordinates: [2]i32) bool {
        const info = self.output_info;
        return coordinates[0] < info.x + info.width and coordinates[0] >= info.x;
    }

    pub fn posInSurface(self: *const Self, coordinates: [2]i32) bool {
        return self.posInX(coordinates) and self.posInY(coordinates);
    }

    pub fn cmp(_: Self, a: Self, b: Self) bool {
        if (a.output_info.x != b.output_info.x) return a.output_info.x < b.output_info.x;
        return a.output_info.y < b.output_info.y;
    }

    pub fn draw(self: *const Self, border_mode: bool, mode: *Mode) void {
        c.glUseProgram(self.egl.main_shader_program.*);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glBindBuffer(c.GL_UNIFORM_BUFFER, self.egl.UBO);
        c.glBindBufferBase(c.GL_UNIFORM_BUFFER, 0, self.egl.UBO);

        self.drawBackground();
        self.drawGrid(border_mode);
        if (mode.* == .Region) self.drawSelection(mode);
    }

    pub fn drawBackground(self: *const Self) void {
        self.config.background_color.set(self.egl.main_shader_program.*);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.VBO[0]);
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
    }

    pub fn drawSelection(self: *const Self, mode: *const Mode) void {
        if (mode.Region) |pos| {
            self.config.grid.selected_color.set(self.egl.main_shader_program.*);

            const info = self.output_info;
            var vertices: [8]i32 = .{
                info.x + info.width, pos[1],
                info.x,              pos[1],
                pos[0],              info.y,
                pos[0],              info.y + info.height,
            };
            c.glLineWidth(self.config.grid.selected_line_width);

            c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.gen_VBO[1]);
            c.glBufferSubData(c.GL_ARRAY_BUFFER, 0, @sizeOf(i32) * vertices.len, &vertices);
            c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
            c.glDrawArrays(c.GL_LINES, 0, vertices.len >> 1);
        }
    }

    pub fn drawGrid(self: *const Self, border_mode: bool) void {
        const info = &self.output_info;
        const grid = &self.config.grid;

        c.glLineWidth(grid.line_width);
        grid.color.set(self.egl.main_shader_program.*);

        if (border_mode) {
            c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.VBO[1]);
            c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
            c.glDrawElements(c.GL_LINE_LOOP, 5, c.GL_UNSIGNED_INT, null);

            return;
        }

        const vert_line_count = @divFloor(info.x, grid.size[0]);
        const hor_line_count = @divFloor(info.y, grid.size[1]);

        var start_pos: [2]i32 = .{
            vert_line_count * grid.size[0] + grid.offset[0],
            hor_line_count * grid.size[1] + grid.offset[1],
        };

        var vertices = std.ArrayList(i32).init(self.alloc);
        defer vertices.deinit();

        while (start_pos[0] <= info.x + info.width) : (start_pos[0] += grid.size[0]) {
            vertices.appendSlice(&[_]i32{
                start_pos[0], info.y,
                start_pos[0], info.y + info.height,
            }) catch @panic("OOM");
        }

        while (start_pos[1] <= info.y + info.height) : (start_pos[1] += grid.size[1]) {
            vertices.appendSlice(&[_]i32{
                info.x,              start_pos[1],
                info.x + info.width, start_pos[1],
            }) catch @panic("OOM");
        }

        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.gen_VBO[0]);
        c.glBufferData(
            c.GL_ARRAY_BUFFER,
            @intCast(@sizeOf(i32) * vertices.items.len),
            @ptrCast(vertices.items),
            c.GL_STATIC_DRAW,
        );
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawArrays(c.GL_LINES, 0, @intCast(vertices.items.len >> 1));
    }

    pub fn getTextSize(self: *const Self, text: []const u32) i32 {
        const scale: f32 = @as(f32, @floatCast(self.config.font.size)) / 256.0;
        var move: f32 = 0;
        for (text) |char| {
            const ch = blk: {
                for (self.config.text.char_info) |ch| {
                    if (ch.key == char) break :blk ch;
                } else unreachable; // getTextSize cant be called with a character that is not in char_info
            };

            const advance: f32 = @floatFromInt(ch.advance[0]);
            move += advance * scale;
        }
        return @intFromFloat(move);
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
    outputs: *[]Surface,
    index: u8 = 0,

    const Self = @This();

    pub fn new(outputs: *[]Surface) Self {
        return Self{ .outputs = outputs, .position = .{ outputs.*[0].output_info.x, outputs.*[0].output_info.y } };
    }

    fn isNewline(self: *Self) bool {
        if (self.index == 0) return false;
        return self.outputs.*[self.index].output_info.x <= self.outputs.*[self.index - 1].output_info.x;
    }

    pub fn next(self: *Self) ?*Surface {
        if (self.index >= self.outputs.len or !self.outputs.*[self.index].isConfigured()) return null;
        const output = &self.outputs.*[self.index];

        self.index += 1;

        return output;
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

                    const info = surface.output_info;

                    { // Background VBO
                        const vertices = [_]i32{
                            info.x,              info.y,
                            info.x + info.width, info.y,
                            info.x,              info.y + info.height,
                            info.x + info.width, info.y + info.height,
                        };

                        c.glBindBuffer(c.GL_ARRAY_BUFFER, surface.egl.VBO[0]);
                        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
                    }

                    { // Border VBO
                        const vertices = [_]i32{
                            info.x,              info.y,
                            info.x + info.width, info.y,
                            info.x,              info.y + info.height,
                            info.x + info.width, info.y + info.height,
                        };

                        c.glBindBuffer(c.GL_ARRAY_BUFFER, surface.egl.VBO[1]);
                        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
                    }

                    const projection = math.orthographicProjection(
                        @floatFromInt(info.x),
                        @floatFromInt(info.x + info.width),
                        @floatFromInt(info.y),
                        @floatFromInt(info.y + info.height),
                    );

                    c.glBindBuffer(c.GL_UNIFORM_BUFFER, surface.egl.UBO);
                    c.glBufferData(
                        c.GL_UNIFORM_BUFFER,
                        @sizeOf(f32) * projection.len * projection[0].len,
                        @ptrCast(&projection),
                        c.GL_STATIC_DRAW,
                    );

                    c.glBindBufferBase(c.GL_UNIFORM_BUFFER, 0, surface.egl.UBO);
                    c.glUniformBlockBinding(
                        surface.egl.main_shader_program.*,
                        c.glGetUniformBlockIndex(surface.egl.main_shader_program.*, "UniformBlock"),
                        0,
                    );

                    if (seto.tree) |tree| tree.destroy();
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
