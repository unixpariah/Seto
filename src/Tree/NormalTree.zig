const std = @import("std");
const c = @import("ffi");
const helpers = @import("helpers");
const zgl = @import("zgl");

const Seto = @import("../main.zig").Seto;
const Output = @import("../Output.zig");
const Grid = @import("../config/Grid.zig");
const Config = @import("../Config.zig");
const OutputInfo = @import("../Output.zig").OutputInfo;
const TotalDimensions = @import("../main.zig").TotalDimensions;

children: []Node,
keys: []const u32,
depth: usize,
arena: std.heap.ArenaAllocator,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, search_keys: []u32, config: *Config, total_dimensions: TotalDimensions) Self {
    var arena = std.heap.ArenaAllocator.init(alloc);
    const nodes = arena.allocator().alloc(Node, search_keys.len) catch @panic("OOM");
    for (search_keys, 0..) |key, i| nodes[i] = Node{ .key = key };

    var tree = Self{
        .children = nodes,
        .keys = search_keys,
        .depth = 1,
        .arena = arena,
    };

    tree.updateCoordinates(total_dimensions, config);

    return tree;
}

pub fn updateCoordinates(self: *Self, total_dimensions: TotalDimensions, config: *Config) void {
    const total_intersections: usize = blk: {
        const width = total_dimensions.width - total_dimensions.x;
        const height = total_dimensions.height - total_dimensions.y;

        const num_x_steps = @ceil(width / config.grid.size[0]);
        const num_y_steps = @ceil(height / config.grid.size[1]);

        break :blk @intFromFloat(num_x_steps * num_y_steps);
    };

    var intersections = std.ArrayList([2]f32).initCapacity(self.arena.allocator(), total_intersections) catch @panic("OOM");
    defer intersections.deinit();

    const start_pos: [2]f32 = .{
        total_dimensions.x + config.grid.offset[0],
        total_dimensions.y + config.grid.offset[1],
    };
    var i = start_pos[0];
    while (i <= total_dimensions.width) : (i += config.grid.size[0]) {
        var j = start_pos[1];
        while (j <= total_dimensions.height) : (j += config.grid.size[1]) {
            intersections.appendAssumeCapacity(.{ i, j });
        }
    }
    const depth: usize = depth: {
        const depth = std.math.log(f32, @floatFromInt(self.keys.len), @floatFromInt(intersections.items.len));
        break :depth @intFromFloat(@ceil(depth));
    };

    if (depth < self.depth) {
        for (depth..self.depth) |_| self.decreaseDepth();
    } else if (depth > self.depth) {
        for (self.depth..depth) |_| self.increaseDepth();
    }

    var char_size: f32 = 0;
    for (self.keys) |key| {
        const char = config.text.atlas.char_info.get(key) orelse continue;

        const scale = config.font.size / 256.0;

        const final_size = char.advance[0] * scale;

        if (final_size > char_size) char_size = final_size;
    }

    const depth_f: f32 = @floatFromInt(depth);
    config.grid.min_size = char_size * (depth_f + 1) + config.font.offset[0];

    var index: usize = 0;
    for (self.children) |*child| {
        child.updateCoordinates(intersections.items, &index);
    }
}

pub fn move(self: *Self, value: [2]f32, total_dimensions: TotalDimensions, config: *Config) void {
    config.grid.move(value);
    var intersections_num: usize = 0;
    for (self.children) |*child| {
        child.move(value, total_dimensions, &intersections_num);
    }

    const total_intersections: usize = blk: {
        const width = total_dimensions.width - (total_dimensions.x + config.grid.offset[0]);
        const height = total_dimensions.height - (total_dimensions.y + config.grid.offset[1]);

        const num_x_steps = @ceil(width / config.grid.size[0]);
        const num_y_steps = @ceil(height / config.grid.size[1]);

        break :blk @intFromFloat(num_x_steps * num_y_steps);
    };

    if (intersections_num == total_intersections) return;
    var intersections = std.ArrayList([2]f32).initCapacity(self.arena.allocator(), total_intersections - intersections_num) catch @panic("OOM");
    defer intersections.deinit();

    if (value[0] > 0) {
        var i = total_dimensions.x + config.grid.offset[0];
        while (i <= total_dimensions.x + value[0]) : (i += config.grid.size[0]) {
            var j = total_dimensions.y + config.grid.offset[1];
            while (j <= total_dimensions.y + total_dimensions.height) : (j += config.grid.size[1]) {
                intersections.appendAssumeCapacity(.{ i, j });
            }
        }
    } else if (value[0] < 0) {
        const iterations = @divExact((total_dimensions.width + value[0]), config.grid.size[0]);

        var i = config.grid.size[0] * iterations + config.grid.offset[0];
        while (i <= total_dimensions.x + total_dimensions.width) : (i += config.grid.size[0]) {
            var j = total_dimensions.y + config.grid.offset[1];
            while (j <= total_dimensions.y + total_dimensions.height) : (j += config.grid.size[1]) {
                intersections.appendAssumeCapacity(.{ i, j });
            }
        }
    }

    if (value[1] > 0) {
        var i = total_dimensions.y + config.grid.offset[1];
        while (i <= total_dimensions.y + value[1]) : (i += config.grid.size[1]) {
            var j = total_dimensions.x + config.grid.offset[0];
            while (j <= total_dimensions.x + total_dimensions.width) : (j += config.grid.size[0]) {
                intersections.appendAssumeCapacity(.{ j, i });
            }
        }
    } else if (value[1] < 0) {
        const iterations = @divExact((total_dimensions.height + value[1]), config.grid.size[1]);

        var i = config.grid.size[1] * iterations + config.grid.offset[1];
        while (i <= total_dimensions.y + total_dimensions.height) : (i += config.grid.size[1]) {
            var j = total_dimensions.x + config.grid.offset[0];
            while (j <= total_dimensions.x + total_dimensions.width) : (j += config.grid.size[0]) {
                intersections.appendAssumeCapacity(.{ j, i });
            }
        }
    }

    var index: usize = 0;
    for (self.children) |*child| {
        child.updateCoordinates(intersections.items, &index);
    }
}

pub fn resize(self: *Self, value: [2]f32, total_dimensions: TotalDimensions, config: *Config) void {
    var intersections_num: usize = 0;
    for (self.children) |*child| {
        child.resize(value, total_dimensions, config, &intersections_num);
    }

    config.grid.resize(value);

    const total_intersections: usize = blk: {
        const width = total_dimensions.width - total_dimensions.x;
        const height = total_dimensions.height - total_dimensions.y;

        const num_x_steps = @ceil(width / config.grid.size[0]);
        const num_y_steps = @ceil(height / config.grid.size[1]);

        break :blk @intFromFloat(num_x_steps * num_y_steps);
    };

    const depth: usize = depth: {
        const depth = std.math.log(f32, @floatFromInt(self.keys.len), @floatFromInt(total_intersections));
        break :depth @intFromFloat(@ceil(depth));
    };

    if (depth != self.depth) {
        self.updateCoordinates(total_dimensions, config);
        return;
    }

    if (intersections_num >= total_intersections) return;

    var intersections = std.ArrayList([2]f32).initCapacity(self.arena.allocator(), total_intersections - intersections_num) catch @panic("OOM");
    defer intersections.deinit();

    if (value[0] < 0) {
        const iterations = @floor((total_dimensions.width - config.grid.offset[0]) / config.grid.size[0]);

        var i = config.grid.size[0] * iterations + config.grid.offset[0];
        while (i >= total_dimensions.x + total_dimensions.width + (value[0] * iterations)) : (i -= config.grid.size[0]) {
            var j = total_dimensions.y + config.grid.offset[1];
            while (j <= total_dimensions.y + total_dimensions.height) : (j += config.grid.size[1]) {
                if (intersections.items.len < intersections.capacity) { // TODO: temporary fix (I hope)
                    intersections.appendAssumeCapacity(.{ i, j });
                }
            }
        }
    }

    if (value[1] < 0) {
        const iterations = @floor((total_dimensions.height - config.grid.offset[1]) / config.grid.size[1]);

        var i = config.grid.size[1] * iterations + config.grid.offset[1];
        while (i >= total_dimensions.y + total_dimensions.height + (value[1] * iterations)) : (i -= config.grid.size[1]) {
            var j = total_dimensions.x + config.grid.offset[0];
            while (j <= total_dimensions.x + total_dimensions.width) : (j += config.grid.size[0]) {
                intersections.appendAssumeCapacity(.{ j, i });
            }
        }
    }

    var index: usize = 0;
    for (self.children) |*child| {
        child.updateCoordinates(intersections.items, &index);
    }
}

pub fn deinit(self: *const Self) void {
    self.arena.deinit();
}

pub fn find(self: *const Self, buffer: *[]u32) !?[2]f32 {
    if (buffer.len == 0) return null;
    for (self.children) |*child| {
        if (child.key == buffer.*[0]) {
            return child.find(buffer, 1);
        }
    }

    return error.KeyNotFound;
}

pub fn drawText(self: *Self, output: *Output, buffer: []u32, config: *Config) void {
    output.egl.text_shader_program.use();
    output.egl.gen_VBO[2].bind(.array_buffer);
    zgl.vertexAttribPointer(0, 2, .float, false, 0, 0);

    const path = self.arena.allocator().alloc(u32, self.depth) catch @panic("OOM");
    for (self.children) |*child| {
        path[0] = child.key;
        if (child.children) |_| {
            child.drawText(config, path, 1, output, buffer);
        } else {
            if (child.coordinates) |coordinates| {
                renderText(
                    output,
                    config,
                    buffer,
                    path,
                    coordinates,
                );
            }
        }
    }

    config.text.renderCall(output.egl.text_shader_program);
}

fn renderText(output: *Output, config: *Config, buffer: []u32, path: []u32, coordinates: [2]f32) void {
    const matches: usize = blk: {
        const min_len = @min(buffer.len, path.len);
        var count: usize = 0;
        while (count < min_len and buffer[count] == path[count]) : (count += 1) {}
        break :blk if (buffer.len > count) 0 else count;
    };

    const coords = .{
        coordinates[0] + config.font.offset[0],
        coordinates[1] + 20 + config.font.offset[1],
    };

    config.text.place(
        config.font.size,
        path[0..matches],
        coords[0],
        coords[1],
        true,
        output.egl.text_shader_program,
    );

    config.text.place(
        config.font.size,
        path[matches..],
        coords[0] + config.text.getSize(config.font.size, path[0..matches]),
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

    fn resize(self: *Node, value: [2]f32, total_dimensions: TotalDimensions, config: *Config, intersections_num: *usize) void {
        if (self.coordinates) |*coordinates| {
            intersections_num.* += 1;
            const num_x_steps = @ceil((coordinates[0] - (total_dimensions.x + config.grid.offset[0])) / config.grid.size[0]);
            const num_y_steps = @ceil((coordinates[1] - (total_dimensions.y + config.grid.offset[1])) / config.grid.size[1]);

            coordinates[0] += num_x_steps * value[0];
            coordinates[1] += num_y_steps * value[1];

            if (coordinates[0] < total_dimensions.x or
                coordinates[0] >= total_dimensions.x + total_dimensions.width or
                coordinates[1] < total_dimensions.y or
                coordinates[1] >= total_dimensions.y + total_dimensions.height)
            {
                intersections_num.* -= 1;
                self.coordinates = null;
            }

            return;
        }

        if (self.children) |children| {
            for (children) |*child| {
                child.resize(value, total_dimensions, config, intersections_num);
            }
        }
    }

    fn move(self: *Node, value: [2]f32, bounds: TotalDimensions, intersections_num: *usize) void {
        if (self.coordinates) |*coords| {
            coords[0] += value[0];
            coords[1] += value[1];
            const in_bounds = coords[0] >= bounds.x and
                coords[0] < bounds.x + bounds.width and
                coords[1] >= bounds.y and
                coords[1] < bounds.y + bounds.height;

            if (!in_bounds) {
                self.coordinates = null;
                return;
            }
            intersections_num.* += 1;
            return;
        }

        if (self.children) |children| {
            for (children) |*child| {
                child.move(value, bounds, intersections_num);
            }
        }
    }

    fn updateCoordinates(self: *Node, intersections: [][2]f32, index: *usize) void {
        if (index.* >= intersections.len) return;

        if (self.children == null) {
            if (self.coordinates == null) {
                self.coordinates = intersections[index.*];
                index.* += 1;
            }
        } else {
            for (self.children.?) |*child| {
                child.updateCoordinates(intersections, index);
            }
        }
    }

    fn isOnScreen(self: *Node) bool {
        if (self.children == null) {
            return self.coordinates != null;
        }

        if (self.children) |children| {
            var hasValidPath = false;
            for (children) |*child| {
                if (child.isOnScreen()) {
                    hasValidPath = true;
                }
            }
            return hasValidPath;
        }

        return false;
    }

    fn find(self: *Node, buffer: *[]u32, index: usize) !?[2]f32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.*.len <= index) {
            if (!self.isOnScreen()) return error.KeyNotFound;
            return null;
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

    fn drawText(self: *Node, config: *Config, path: []u32, index: u8, output: *Output, buffer: []u32) void {
        if (self.children) |children| {
            for (children) |*child| {
                path[index] = child.key;

                if (child.coordinates) |coordinates| {
                    if (coordinates[1] < output.info.y + output.info.height + config.grid.size[1] and
                        coordinates[1] >= output.info.y - config.grid.size[1] and
                        coordinates[0] < output.info.x + output.info.width + config.grid.size[0] and
                        coordinates[0] >= output.info.x - config.grid.size[0])
                    {
                        renderText(
                            output,
                            config,
                            buffer,
                            path,
                            coordinates,
                        );
                    }
                    continue;
                }
                child.drawText(config, path, index + 1, output, buffer);
            }
        }
    }

    fn increaseDepth(self: *Node, keys: []const u32, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| child.increaseDepth(keys, alloc);
        } else {
            self.coordinates = null;
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
