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

    fn destroy(self: *OutputInfo, alloc: mem.Allocator) void {
        alloc.free(self.name.?);
        alloc.free(self.description.?);
    }
};

egl: EglSurface,
layer_surface: *zwlr.LayerSurfaceV1,
surface: *wl.Surface,
alloc: mem.Allocator,
info: OutputInfo,
xdg_output: *zxdg.OutputV1,

const Self = @This();

pub fn new(
    egl: EglSurface,
    surface: *wl.Surface,
    layer_surface: *zwlr.LayerSurfaceV1,
    alloc: mem.Allocator,
    xdg_output: *zxdg.OutputV1,
    output_info: OutputInfo,
) Self {
    return .{
        .egl = egl,
        .surface = surface,
        .layer_surface = layer_surface,
        .alloc = alloc,
        .info = output_info,
        .xdg_output = xdg_output,
    };
}

fn posInY(self: *const Self, coordinates: [2]i32) bool {
    return coordinates[1] < self.info.y + self.info.height and coordinates[1] >= self.info.y;
}

fn posInX(self: *const Self, coordinates: [2]i32) bool {
    return coordinates[0] < self.info.x + self.info.width and coordinates[0] >= self.info.x;
}

pub fn posInSurface(self: *const Self, coordinates: [2]i32) bool {
    return self.posInX(coordinates) and self.posInY(coordinates);
}

pub fn cmp(_: Self, a: Self, b: Self) bool {
    if (a.info.x != b.info.x) return a.info.x < b.info.x;
    return a.info.y < b.info.y;
}

pub fn draw(self: *const Self, config: *Config, border_mode: bool, mode: *Mode) void {
    c.glUseProgram(self.egl.main_shader_program.*);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
    c.glClearColor(0, 0, 0, 0);

    c.glBindBuffer(c.GL_UNIFORM_BUFFER, self.egl.UBO);
    c.glBindBufferBase(c.GL_UNIFORM_BUFFER, 0, self.egl.UBO);

    self.drawBackground(config);
    self.drawGrid(config, border_mode);
    if (mode.* == .Region) self.drawSelection(config, mode);
}

pub fn drawBackground(self: *const Self, config: *Config) void {
    config.background_color.set(self.egl.main_shader_program.*);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.VBO[0]);
    c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
    c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
}

pub fn drawSelection(self: *const Self, config: *Config, mode: *const Mode) void {
    if (mode.Region) |pos| {
        config.grid.selected_color.set(self.egl.main_shader_program.*);

        var vertices: [8]i32 = .{
            self.info.x + self.info.width, pos[1],
            self.info.x,                   pos[1],
            pos[0],                        self.info.y,
            pos[0],                        self.info.y + self.info.height,
        };
        c.glLineWidth(config.grid.selected_line_width);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.gen_VBO[1]);
        c.glBufferSubData(c.GL_ARRAY_BUFFER, 0, @sizeOf(i32) * vertices.len, &vertices);
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawArrays(c.GL_LINES, 0, vertices.len >> 1);
    }
}

pub fn drawGrid(self: *const Self, config: *Config, border_mode: bool) void {
    const grid = &config.grid;

    c.glLineWidth(grid.line_width);
    grid.color.set(self.egl.main_shader_program.*);

    if (border_mode) {
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.egl.VBO[1]);
        c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);
        c.glDrawElements(c.GL_LINE_LOOP, 5, c.GL_UNSIGNED_INT, null);

        return;
    }

    const vert_line_count = @divFloor(self.info.x, grid.size[0]);
    const hor_line_count = @divFloor(self.info.y, grid.size[1]);

    var start_pos: [2]i32 = .{
        vert_line_count * grid.size[0] + grid.offset[0],
        hor_line_count * grid.size[1] + grid.offset[1],
    };

    var vertices = std.ArrayList(i32).init(self.alloc);
    defer vertices.deinit();

    while (start_pos[0] <= self.info.x + self.info.width) : (start_pos[0] += grid.size[0]) {
        vertices.appendSlice(&[_]i32{
            start_pos[0], self.info.y,
            start_pos[0], self.info.y + self.info.height,
        }) catch @panic("OOM");
    }

    while (start_pos[1] <= self.info.y + self.info.height) : (start_pos[1] += grid.size[1]) {
        vertices.appendSlice(&[_]i32{
            self.info.x,                   start_pos[1],
            self.info.x + self.info.width, start_pos[1],
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

pub fn isConfigured(self: *const Self) bool {
    return self.info.width > 0 and self.info.height > 0;
}

pub fn destroy(self: *Self) void {
    self.layer_surface.destroy();
    self.surface.destroy();
    self.info.destroy(self.alloc);
    self.xdg_output.destroy();
    self.egl.destroy();
}

pub fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
        .configure => |configure| {
            for (seto.outputs.items) |*output| {
                if (output.layer_surface == lsurf) {
                    output.layer_surface.setSize(configure.width, configure.height);
                    output.layer_surface.ackConfigure(configure.serial);
                    output.egl.resize(.{ configure.width, configure.height });
                }
            }
        },
        .closed => {},
    }
}

pub fn xdgOutputListener(
    xdg_output: *zxdg.OutputV1,
    event: zxdg.OutputV1.Event,
    seto: *Seto,
) void {
    for (seto.outputs.items) |*output| {
        if (output.xdg_output == xdg_output) {
            switch (event) {
                .name => |e| {
                    output.info.name = seto.alloc.dupe(u8, mem.span(e.name)) catch @panic("OOM");
                },
                .description => |e| {
                    output.info.description = seto.alloc.dupe(u8, mem.span(e.description)) catch @panic("OOM");
                },
                .logical_position => |pos| {
                    output.info.x = pos.x;
                    output.info.y = pos.y;
                },
                .logical_size => |size| {
                    output.info.height = size.height;
                    output.info.width = size.width;

                    seto.updateDimensions();

                    { // Background VBO
                        const vertices = [_]i32{
                            output.info.x,                     output.info.y,
                            output.info.x + output.info.width, output.info.y,
                            output.info.x,                     output.info.y + output.info.height,
                            output.info.x + output.info.width, output.info.y + output.info.height,
                        };

                        c.glBindBuffer(c.GL_ARRAY_BUFFER, output.egl.VBO[0]);
                        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
                    }

                    { // Border VBO
                        const vertices = [_]i32{
                            output.info.x,                     output.info.y,
                            output.info.x + output.info.width, output.info.y,
                            output.info.x,                     output.info.y + output.info.height,
                            output.info.x + output.info.width, output.info.y + output.info.height,
                        };

                        c.glBindBuffer(c.GL_ARRAY_BUFFER, output.egl.VBO[1]);
                        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(i32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
                    }

                    const uniform_object = struct {
                        projection: math.Mat4,
                        start_color: [2][4]f32,
                        end_color: [2][4]f32,
                        degrees: [2]f32,
                    }{
                        .projection = math.orthographicProjection(
                            @floatFromInt(output.info.x),
                            @floatFromInt(output.info.x + output.info.width),
                            @floatFromInt(output.info.y),
                            @floatFromInt(output.info.y + output.info.height),
                        ),
                        .start_color = .{
                            seto.config.font.color.start_color,
                            seto.config.font.highlight_color.start_color,
                        },
                        .end_color = .{
                            seto.config.font.color.end_color,
                            seto.config.font.highlight_color.end_color,
                        },
                        .degrees = .{
                            seto.config.font.color.deg,
                            seto.config.font.highlight_color.deg,
                        },
                    };

                    c.glBindBuffer(c.GL_UNIFORM_BUFFER, output.egl.UBO);
                    c.glBufferData(
                        c.GL_UNIFORM_BUFFER,
                        @sizeOf(@TypeOf(uniform_object)),
                        @ptrCast(&uniform_object),
                        c.GL_STATIC_DRAW,
                    );

                    c.glBindBufferBase(c.GL_UNIFORM_BUFFER, 0, output.egl.UBO);
                    c.glUniformBlockBinding(
                        output.egl.main_shader_program.*,
                        c.glGetUniformBlockIndex(output.egl.main_shader_program.*, "UniformBlock"),
                        0,
                    );

                    if (seto.tree) |tree| tree.destroy();
                    seto.tree = Tree.new(
                        seto.config.keys.search,
                        seto.alloc,
                        &seto.config,
                        &seto.outputs.items,
                    );
                },
                .done => {},
            }
        }
    }
}
