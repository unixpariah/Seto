const std = @import("std");
const zgl = @import("zgl");
const helpers = @import("helpers");

const Text = @import("../Text.zig");
const Seto = @import("../main.zig").Seto;
const Output = @import("../Output.zig");
const Grid = @import("../config/Grid.zig");
const Config = @import("../Config.zig");
const OutputInfo = @import("../Output.zig").OutputInfo;
const TotalDimensions = @import("../main.zig").TotalDimensions;

children: []Node,
search_keys: []const u32,
depth: usize,
arena: std.heap.ArenaAllocator,
config_ptr: *Config,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, search_keys: []u32, config: *Config, text: *Text, outputs: []OutputInfo) Self {
    var arena = std.heap.ArenaAllocator.init(alloc);
    const nodes = arena.allocator().alloc(Node, search_keys.len) catch @panic("OOM");
    for (search_keys, 0..) |key, i| nodes[i] = Node{ .key = key };

    var tree = Self{
        .children = nodes,
        .search_keys = search_keys,
        .depth = 1,
        .arena = arena,
        .config_ptr = config,
    };

    tree.updateCoordinates(outputs, config, text);

    return tree;
}

pub fn updateCoordinates(self: *Self, outputs: []OutputInfo, config: *Config, text: *Text) void {
    const total_intersections: usize = outputs.len * 4;

    var intersections = std.ArrayList([2]f32).initCapacity(self.arena.allocator(), total_intersections) catch @panic("OOM");
    defer intersections.deinit();

    for (outputs) |output| {
        intersections.appendSliceAssumeCapacity(&[_][2]f32{
            .{ output.x, output.y },
            .{ output.x, output.y + output.height - 1 },
            .{ output.x + output.width - 1, output.y },
            .{ output.x + output.width - 1, output.y + output.height - 1 },
        });
    }

    const depth: usize = depth: {
        const depth = std.math.log(f32, @floatFromInt(self.search_keys.len), @floatFromInt(intersections.items.len));
        break :depth @intFromFloat(@ceil(depth));
    };

    if (depth < self.depth) {
        for (depth..self.depth) |_| self.decreaseDepth();
    } else if (depth > self.depth) {
        for (self.depth..depth) |_| self.increaseDepth();
    }

    var char_size: f32 = 0;
    for (self.search_keys) |key| {
        const char = text.atlas.char_info.get(key) orelse continue;

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

pub fn drawText(self: *Self, output: *Output, buffer: []u32, config: *Config, text: *Text) void {
    output.egl.text_shader_program.use();
    output.egl.gen_VBO[2].bind(.array_buffer);
    zgl.vertexAttribPointer(0, 2, .float, false, 0, 0);

    const path = self.arena.allocator().alloc(u32, self.depth) catch @panic("OOM");
    for (self.children) |*child| {
        path[0] = child.key;
        if (child.children) |_| {
            child.drawText(text, config, path, 1, output, buffer);
        } else {
            if (child.coordinates) |coordinates| {
                renderText(
                    output,
                    config,
                    text,
                    buffer,
                    path,
                    coordinates,
                );
            }
        }
    }

    text.renderCall(output.egl.text_shader_program);
}

const Position = enum {
    top_left,
    bottom_left,
    top_right,
    bottom_right,
    other,

    pub fn from(info: OutputInfo, coords: [2]f32) Position {
        const epsilon: f32 = 0.1;
        const is_left = @abs(coords[0] - info.x) < epsilon;
        const is_right = @abs(coords[0] - (info.x + info.width - 1)) < epsilon;
        const is_top = @abs(coords[1] - info.y) < epsilon;
        const is_bottom = @abs(coords[1] - (info.y + info.height - 1)) < epsilon;

        return if (is_left and is_top)
            .top_left
        else if (is_left and is_bottom)
            .bottom_left
        else if (is_right and is_top)
            .top_right
        else if (is_right and is_bottom)
            .bottom_right
        else
            .other;
    }
};

fn renderText(output: *Output, config: *Config, text: *Text, buffer: []u32, path: []u32, coordinates: [2]f32) void {
    const matches: usize = blk: {
        const min_len = @min(buffer.len, path.len);
        var count: usize = 0;
        while (count < min_len and buffer[count] == path[count]) : (count += 1) {}
        break :blk if (buffer.len > count) 0 else count;
    };

    const coords = blk: {
        const text_size = text.getSize(config.font.size, path);
        const pos = Position.from(output.info, coordinates);

        break :blk switch (pos) {
            .top_left => .{
                coordinates[0] + config.font.offset[0],
                coordinates[1] + text_size.height + config.font.offset[1],
            },
            .bottom_left => .{
                coordinates[0] + config.font.offset[0],
                coordinates[1] - config.font.offset[1],
            },
            .top_right => .{
                coordinates[0] - text_size.width - config.font.offset[0],
                coordinates[1] + text_size.height + config.font.offset[1],
            },
            .bottom_right => .{
                coordinates[0] - text_size.width - config.font.offset[0],
                coordinates[1] - config.font.offset[1],
            },
            .other => return,
        };
    };

    text.place(
        config.font.size,
        path[0..matches],
        coords[0],
        coords[1],
        true,
        output.egl.text_shader_program,
    );

    const text_size = text.getSize(config.font.size, path[0..matches]);

    text.place(
        config.font.size,
        path[matches..],
        coords[0] + text_size.width,
        coords[1],
        false,
        output.egl.text_shader_program,
    );
}

fn increaseDepth(self: *Self) void {
    self.depth += 1;
    for (self.children) |*child| {
        child.increaseDepth(self.search_keys, self.arena.allocator());
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
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return false;
                return child.isOnScreen();
            }
        }

        return true;
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

    fn drawText(self: *Node, text: *Text, config: *Config, path: []u32, index: u8, output: *Output, buffer: []u32) void {
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
                            text,
                            buffer,
                            path,
                            coordinates,
                        );
                    }
                    continue;
                }
                child.drawText(text, config, path, index + 1, output, buffer);
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
