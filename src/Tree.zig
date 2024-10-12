const std = @import("std");
const c = @import("ffi");
const helpers = @import("helpers");

const Seto = @import("main.zig").Seto;
const Output = @import("Output.zig");
const Grid = @import("config/Grid.zig");
const Config = @import("Config.zig");
const OutputInfo = @import("Output.zig").OutputInfo;
const TotalDimensions = @import("main.zig").TotalDimensions;

children: []Node,
keys: []const u32,
depth: usize,
arena: std.heap.ArenaAllocator,
total_dimensions: *TotalDimensions,
config_ptr: *Config,
outputs_ptr: *const []Output,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, config: *Config, outputs: *const []Output) Self {
    var arena = std.heap.ArenaAllocator.init(alloc);
    const nodes = arena.allocator().alloc(Node, config.keys.search.len) catch @panic("OOM");
    for (config.keys.search, 0..) |key, i| nodes[i] = Node{ .key = key };

    var tree = Self{
        .children = nodes,
        .keys = config.keys.search,
        .depth = 1,
        .arena = arena,
        .total_dimensions = outputs.*[0].total_dimensions_ptr,
        .config_ptr = config,
        .outputs_ptr = outputs,
    };

    tree.updateCoordinates(false);

    return tree;
}

pub fn updateCoordinates(self: *Self, border_mode: bool) void {
    const total_intersections: usize = blk: {
        if (border_mode) {
            break :blk self.outputs_ptr.len * 4;
        } else {
            const width = self.total_dimensions.width - self.total_dimensions.x;
            const height = self.total_dimensions.height - self.total_dimensions.y;

            const num_x_steps = @ceil(width / self.config_ptr.grid.size[0]);
            const num_y_steps = @ceil(height / self.config_ptr.grid.size[1]);

            break :blk @intFromFloat(num_x_steps * num_y_steps);
        }
    };

    var intersections = std.ArrayList([2]f32).initCapacity(self.arena.allocator(), total_intersections) catch @panic("OOM");
    defer intersections.deinit();

    if (border_mode) {
        for (self.outputs_ptr.*) |output| {
            intersections.appendSliceAssumeCapacity(&[_][2]f32{
                .{ output.info.x, output.info.y },
                .{ output.info.x, output.info.y + output.info.height - 1 },
                .{ output.info.x + output.info.width - 1, output.info.y },
                .{ output.info.x + output.info.width - 1, output.info.y + output.info.height - 1 },
            });
        }
    } else {
        const start_pos: [2]f32 = .{
            self.total_dimensions.x + self.config_ptr.grid.offset[0],
            self.total_dimensions.y + self.config_ptr.grid.offset[1],
        };
        var i = start_pos[0];
        while (i <= self.total_dimensions.width - 1) : (i += self.config_ptr.grid.size[0]) {
            var j = start_pos[1];
            while (j <= self.total_dimensions.height - 1) : (j += self.config_ptr.grid.size[1]) {
                intersections.appendAssumeCapacity(.{ i, j });
            }
        }
    }
    const depth: usize = depth: {
        const depth = std.math.log(f32, @floatFromInt(self.config_ptr.keys.search.len), @floatFromInt(intersections.items.len));
        break :depth @intFromFloat(@ceil(depth));
    };

    if (depth < self.depth) {
        for (depth..self.depth) |_| self.decreaseDepth();
    } else if (depth > self.depth) {
        for (self.depth..depth) |_| self.increaseDepth();
    }

    var char_size: f32 = 0;
    for (self.config_ptr.keys.search) |key| {
        const char = self.config_ptr.text.char_info[key];

        const scale = self.config_ptr.font.size / 256.0;

        const final_size = char.advance[0] * scale;

        if (final_size > char_size) char_size = final_size;
    }

    const depth_f: f32 = @floatFromInt(depth);
    self.config_ptr.*.grid.max_size[0] = char_size * (depth_f + 1) + self.config_ptr.font.offset[0];

    var index: usize = 0;
    for (self.children) |*child| {
        child.updateCoordinates(intersections.items, &index);
    }
}

pub fn deinit(self: *const Self) void {
    self.arena.deinit();
}

pub fn find(self: *Self, buffer: *[]u32) ![2]f32 {
    if (buffer.len == 0) return error.EndNotReached;
    for (self.children) |*child| {
        if (child.key == buffer.*[0]) {
            return child.find(buffer, 1);
        }
    }

    return error.KeyNotFound;
}

pub fn drawText(self: *Self, output: *Output, buffer: []u32, border_mode: bool) void {
    c.glUseProgram(output.egl.text_shader_program);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, output.egl.gen_VBO[2]);
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);

    const path = self.arena.allocator().alloc(u32, self.depth) catch @panic("OOM");
    for (self.children) |*child| {
        path[0] = child.key;
        if (child.children) |_| {
            child.drawText(self.config_ptr, path, 1, output, buffer, border_mode);
        } else {
            if (child.coordinates) |coordinates| {
                renderText(
                    output,
                    self.config_ptr,
                    buffer,
                    path,
                    border_mode,
                    coordinates,
                );
            }
        }
    }

    self.config_ptr.text.renderCall(output.egl.text_shader_program);
}

fn renderText(output: *Output, config: *Config, buffer: []u32, path: []u32, border_mode: bool, coordinates: [2]f32) void {
    var matches: u8 = 0;
    for (buffer, 0..) |char, i| {
        if (path[i] == char) matches += 1 else break;
    }
    if (buffer.len > matches) matches = 0;

    const coords = blk: {
        if (border_mode) {
            const text_size = config.text.getSize(path);
            break :blk if (coordinates[0] == output.info.x and coordinates[1] == output.info.y)
                .{ coordinates[0] + 5, coordinates[1] + 25 }
            else if (coordinates[0] == output.info.x and coordinates[1] == output.info.y + output.info.height - 1)
                .{ coordinates[0] + 5, coordinates[1] - 15 }
            else if (coordinates[0] == output.info.x + output.info.width - 1 and coordinates[1] == output.info.y)
                .{ coordinates[0] - 15 - text_size, coordinates[1] + 25 }
            else if (coordinates[0] == output.info.x + output.info.width - 1 and coordinates[1] == output.info.y + output.info.height - 1)
                .{ coordinates[0] - 15 - text_size, coordinates[1] - 15 }
            else
                return;
        } else {
            break :blk .{
                coordinates[0] + config.font.offset[0],
                coordinates[1] + 20 + config.font.offset[1],
            };
        }
    };

    config.text.place(
        path[0..matches],
        coords[0],
        coords[1],
        true,
        output.egl.text_shader_program,
    );

    config.text.place(
        path[matches..],
        coords[0] + config.text.getSize(path[0..matches]),
        coords[1],
        false,
        output.egl.text_shader_program,
    );
}

fn increaseDepth(self: *Self) void {
    self.depth += 1;
    for (self.children) |*child| {
        child.increaseDepth(self.keys, self.arena.allocator());
    }
}

fn decreaseDepth(self: *Self) void {
    self.depth -= 1;
    for (self.children) |*child| {
        child.decreaseDepth(self.arena.allocator());
    }
}

const Node = struct {
    key: u32,
    children: ?[]Node = null,
    coordinates: ?[2]f32 = null,

    fn updateCoordinates(self: *Node, intersections: [][2]f32, index: *usize) void {
        if (self.children == null) {
            if (index.* < intersections.len) {
                self.coordinates = intersections[index.*];
                index.* += 1;
            } else {
                self.coordinates = null;
            }
        } else {
            for (self.children.?) |*child| {
                child.updateCoordinates(intersections, index);
            }
        }
    }

    fn isOnScreen(self: *Node) bool {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return false;
                return child.isOnScreen();
            }
        }

        return true;
    }

    fn find(self: *Node, buffer: *[]u32, index: usize) ![2]f32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.*.len <= index) {
            if (!self.isOnScreen()) return error.KeyNotFound;
            return error.EndNotReached;
        }
        if (self.children) |children| {
            for (children) |*child| {
                if (child.key == buffer.*[index]) {
                    return child.find(buffer, index + 1);
                }
            }
        }

        return error.KeyNotFound;
    }

    fn drawText(self: *Node, config: *Config, path: []u32, index: u8, output: *Output, buffer: []u32, border_mode: bool) void {
        if (self.children) |children| {
            for (children) |*child| {
                path[index] = child.key;

                if (child.coordinates) |coordinates| {
                    renderText(
                        output,
                        config,
                        buffer,
                        path,
                        border_mode,
                        coordinates,
                    );
                    continue;
                }
                child.drawText(config, path, index + 1, output, buffer, border_mode);
            }
        }
    }

    fn increaseDepth(self: *Node, keys: []const u32, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| child.increaseDepth(keys, alloc);
        } else {
            self.createChildren(keys, alloc);
        }
    }

    fn decreaseDepth(self: *Node, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null) {
                    alloc.free(self.children.?);
                    self.children = null;
                    return;
                } else {
                    child.decreaseDepth(alloc);
                }
            }
        }
    }

    fn createChildren(self: *Node, keys: []const u32, alloc: std.mem.Allocator) void {
        self.coordinates = null;
        if (self.children == null) {
            const nodes = alloc.alloc(Node, keys.len) catch @panic("OOM");
            for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };
            self.children = nodes;
        }
    }
};
