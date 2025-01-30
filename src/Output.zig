const std = @import("std");
const zgl = @import("zgl");
const wayland = @import("wayland");
const helpers = @import("helpers");
const math = @import("math");
const c = @import("ffi");

const mem = std.mem;
const posix = std.posix;
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;

const TotalDimensions = @import("State.zig").TotalDimensions;
const Mode = @import("Config.zig").Mode;
const Seto = @import("main.zig").Seto;
const State = @import("State.zig");
const Config = @import("Config.zig");
const EglSurface = @import("Egl.zig").EglSurface;
const Tree = @import("Tree/NormalTree.zig");
const Trees = @import("Tree/Trees.zig");
const Color = helpers.Color;

pub const OutputInfo = struct {
    id: u32,
    name: ?[]const u8 = null,
    height: f32 = 0,
    width: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    refresh: f32 = 0,

    pub fn deinit(self: *OutputInfo, alloc: mem.Allocator) void {
        if (self.name) |name| alloc.free(name);
    }

    pub fn cmp(_: OutputInfo, a: OutputInfo, b: OutputInfo) bool {
        if (a.x != b.x) return a.x < b.x;
        return a.y < b.y;
    }
};

egl: EglSurface,
layer_surface: *zwlr.LayerSurfaceV1,
surface: *wl.Surface,
alloc: mem.Allocator,
info: OutputInfo,
xdg_output: *zxdg.OutputV1,
wl_output: *wl.Output,

const Self = @This();

pub fn init(
    egl: EglSurface,
    surface: *wl.Surface,
    layer_surface: *zwlr.LayerSurfaceV1,
    alloc: mem.Allocator,
    xdg_output: *zxdg.OutputV1,
    wl_output: *wl.Output,
    output_info: OutputInfo,
) Self {
    return .{
        .egl = egl,
        .surface = surface,
        .layer_surface = layer_surface,
        .alloc = alloc,
        .info = output_info,
        .xdg_output = xdg_output,
        .wl_output = wl_output,
    };
}

fn posInY(self: *const Self, coordinates: [2]f32) bool {
    return coordinates[1] < self.info.y + self.info.height and coordinates[1] >= self.info.y;
}

fn posInX(self: *const Self, coordinates: [2]f32) bool {
    return coordinates[0] < self.info.x + self.info.width and coordinates[0] >= self.info.x;
}

pub fn posInSurface(self: *const Self, coordinates: [2]f32) bool {
    return self.posInX(coordinates) and self.posInY(coordinates);
}

pub fn draw(self: *const Self, config: *Config, state: State) void {
    self.egl.main_shader_program.use();
    zgl.clear(.{ .color = true });

    self.egl.UBO.bind(.uniform_buffer);
    zgl.bindBufferBase(.uniform_buffer, 0, self.egl.UBO);

    self.drawBackground(config);
    self.drawGrid(config, state);
    if (config.mode == .Region) self.drawSelection(config);
}

pub fn drawBackground(self: *const Self, config: *Config) void {
    config.background_color.set(self.egl.main_shader_program);

    self.egl.background_buffer.bind(.array_buffer);
    zgl.vertexAttribPointer(zgl.getAttribLocation(self.egl.main_shader_program, "in_pos").?, 2, .float, false, 0, 0);
    zgl.drawElements(.triangles, 6, .unsigned_int, 0);
}

pub fn drawSelection(self: *const Self, config: *Config) void {
    if (config.mode.Region) |pos| {
        config.grid.selected_color.set(self.egl.main_shader_program);

        var vertices: [8]f32 = .{
            self.info.x + self.info.width, pos[1],
            self.info.x,                   pos[1],
            pos[0],                        self.info.y,
            pos[0],                        self.info.y + self.info.height,
        };
        zgl.lineWidth(config.grid.selected_line_width);

        self.egl.gen_VBO[1].bind(.array_buffer);
        self.egl.gen_VBO[1].subData(0, f32, &vertices);
        zgl.vertexAttribPointer(zgl.getAttribLocation(self.egl.main_shader_program, "in_pos").?, 2, .float, false, 0, 0);
        zgl.drawArrays(.lines, 0, vertices.len >> 1);
    }
}

pub fn drawGrid(self: *const Self, config: *Config, state: State) void {
    zgl.lineWidth(config.grid.line_width);
    config.grid.color.set(self.egl.main_shader_program);

    if (state.border_mode) {
        self.egl.background_buffer.bind(.array_buffer);
        zgl.vertexAttribPointer(zgl.getAttribLocation(self.egl.main_shader_program, "in_pos").?, 2, .float, false, 0, 0);
        zgl.drawElements(.line_loop, 5, .unsigned_int, 0);

        return;
    }

    const num_x_step = @ceil((self.info.x - state.total_dimensions.x - config.grid.offset[0]) / config.grid.size[0]);
    const num_y_step = @ceil((self.info.y - state.total_dimensions.y - config.grid.offset[1]) / config.grid.size[1]);

    var start_pos: [2]f32 = .{
        state.total_dimensions.x + num_x_step * config.grid.size[0] + config.grid.offset[0],
        state.total_dimensions.y + num_y_step * config.grid.size[1] + config.grid.offset[1],
    };

    const vertices_count: usize = blk: {
        const num_x_steps = @ceil(self.info.width / config.grid.size[0]);
        const num_y_steps = @ceil(self.info.height / config.grid.size[1]);

        break :blk @intFromFloat((num_x_steps + 1 + num_y_steps + 1) * 4);
    };

    var vertices = std.ArrayList(f32).initCapacity(self.alloc, vertices_count) catch @panic("OOM");
    defer vertices.deinit();

    while (start_pos[0] <= self.info.x + self.info.width) : (start_pos[0] += config.grid.size[0]) {
        vertices.appendSliceAssumeCapacity(&[_]f32{
            start_pos[0], self.info.y,
            start_pos[0], self.info.y + self.info.height,
        });
    }

    while (start_pos[1] <= self.info.y + self.info.height) : (start_pos[1] += config.grid.size[1]) {
        vertices.appendSliceAssumeCapacity(&[_]f32{
            self.info.x,                   start_pos[1],
            self.info.x + self.info.width, start_pos[1],
        });
    }

    self.egl.gen_VBO[0].bind(.array_buffer);
    self.egl.gen_VBO[0].data(f32, vertices.items, .static_draw);
    zgl.vertexAttribPointer(zgl.getAttribLocation(self.egl.main_shader_program, "in_pos").?, 2, .float, false, 0, 0);
    zgl.drawArrays(.lines, 0, vertices.items.len >> 1);
}

pub fn isConfigured(self: *const Self) bool {
    return self.info.width > 0 and self.info.height > 0;
}

pub fn deinit(self: *Self) void {
    self.layer_surface.destroy();
    self.surface.destroy();
    self.info.deinit(self.alloc);
    self.xdg_output.destroy();
    self.egl.deinit();
}

pub fn layerSurfaceListener(layer_surface: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    var output = for (seto.outputs.items) |output| {
        if (output.layer_surface == layer_surface) break output;
    } else return;

    switch (event) {
        .configure => |configure| {
            output.layer_surface.setSize(configure.width, configure.height);
            output.layer_surface.ackConfigure(configure.serial);
            output.egl.resize(.{ configure.width, configure.height });
        },
        .closed => {},
    }
}

pub fn xdgOutputListener(
    xdg_output: *zxdg.OutputV1,
    event: zxdg.OutputV1.Event,
    seto: *Seto,
) void {
    const output: *Self = for (seto.outputs.items) |*output| {
        if (output.xdg_output == xdg_output) {
            break output;
        }
    } else unreachable;

    switch (event) {
        .name => |e| {
            output.info.name = seto.alloc.dupe(u8, mem.span(e.name)) catch @panic("OOM");
        },
        .logical_position => |pos| {
            output.info.x = @floatFromInt(pos.x);
            output.info.y = @floatFromInt(pos.y);
        },
        .logical_size => |size| {
            output.info.height = @floatFromInt(size.height);
            output.info.width = @floatFromInt(size.width);

            output.egl.background_buffer.bind(.array_buffer);
            output.egl.background_buffer.data(f32, &.{
                output.info.x,                     output.info.y,
                output.info.x + output.info.width, output.info.y,
                output.info.x,                     output.info.y + output.info.height,
                output.info.x + output.info.width, output.info.y + output.info.height,
            }, .static_draw);

            const uniform_object = struct {
                projection: math.Mat4,
                start_color: [2][4]f32,
                end_color: [2][4]f32,
                degrees: [2][4]f32,
            }{
                .projection = math.orthographicProjection(
                    output.info.x,
                    output.info.x + output.info.width,
                    output.info.y,
                    output.info.y + output.info.height,
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
                    .{ seto.config.font.color.deg, 0, 0, 0 },
                    .{ seto.config.font.highlight_color.deg, 0, 0, 0 },
                },
            };

            output.egl.UBO.bind(.uniform_buffer);
            output.egl.UBO.data(@TypeOf(uniform_object), &[_]@TypeOf(uniform_object){uniform_object}, .static_draw);
            zgl.bindBufferBase(.uniform_buffer, 0, output.egl.UBO);
            zgl.uniformBlockBinding(
                output.egl.main_shader_program,
                output.egl.main_shader_program.uniformBlockIndex("UniformBlock").?,
                0,
            );

            var outputs_info = seto.alloc.alloc(OutputInfo, seto.outputs.items.len) catch @panic("");
            defer seto.alloc.free(outputs_info);
            for (seto.outputs.items, 0..) |o, i| {
                outputs_info[i] = o.info;
            }

            seto.state.total_dimensions = TotalDimensions.updateDimensions(outputs_info);

            if (seto.trees) |*trees| {
                trees.deinit();
                seto.trees = Trees.init(output.alloc, seto.config, &seto.state, seto.text, outputs_info);
                return;
            }
            seto.trees = Trees.init(output.alloc, seto.config, &seto.state, seto.text, outputs_info);
        },
        else => {},
    }
}

pub fn wlOutputListener(wl_output: *wl.Output, event: wl.Output.Event, seto: *Seto) void {
    var output = for (seto.outputs.items) |output| {
        if (output.wl_output == wl_output) break output;
    } else return;

    switch (event) {
        .mode => |mode| {
            output.info.refresh = @as(f32, @floatFromInt(mode.refresh)) / 1000.0;
        },
        else => {},
    }
}
