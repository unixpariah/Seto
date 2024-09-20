const std = @import("std");
const c = @import("ffi");
const helpers = @import("helpers");

const Seto = @import("main.zig").Seto;
const Output = @import("Output.zig");
const Grid = @import("config/Grid.zig");
const Config = @import("Config.zig");

children: []Node,
keys: []const u32,
depth: u8,
arena: std.heap.ArenaAllocator,

const Self = @This();

pub fn new(keys: []const u32, alloc: std.mem.Allocator, config: *Config, outputs: *[]Output) Self {
    var arena = std.heap.ArenaAllocator.init(alloc);
    const nodes = arena.allocator().alloc(Node, keys.len) catch @panic("OOM");
    for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };

    var tree = Self{
        .children = nodes,
        .keys = keys,
        .depth = 1,
        .arena = arena,
    };

    var tmp = std.ArrayList(u32).init(alloc);
    tree.updateCoordinates(config, false, outputs, &tmp);

    return tree;
}

pub fn destroy(self: *const Self) void {
    self.arena.deinit();
}

pub fn find(self: *Self, buffer: *[]u32) ![2]i32 {
    if (buffer.len == 0) return error.EndNotReached;
    for (self.children) |*child| {
        if (child.key == buffer.*[0]) {
            return child.find(buffer, 1);
        }
    }

    return error.KeyNotFound;
}

pub fn drawText(self: *Self, output: *Output, config: *Config, buffer: []u32, border_mode: bool) void {
    c.glUseProgram(output.egl.text_shader_program.*);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, output.egl.gen_VBO[2]);
    c.glVertexAttribPointer(0, 2, c.GL_INT, c.GL_FALSE, 0, null);

    const path = self.arena.allocator().alloc(u32, self.depth) catch @panic("OOM");
    for (self.children) |*child| {
        path[0] = child.key;
        if (child.children) |_| {
            child.drawText(config, path, 1, output, buffer, border_mode);
        } else {
            if (child.coordinates) |coordinates| {
                renderText(
                    output,
                    config,
                    buffer,
                    path,
                    border_mode,
                    coordinates,
                );
            }
        }
    }
}

fn renderText(output: *Output, config: *Config, buffer: []u32, path: []u32, border_mode: bool, coordinates: [2]i32) void {
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
        @floatFromInt(coords[0]),
        @floatFromInt(coords[1]),
        .highlight_color,
        output.egl.text_shader_program,
    );

    config.text.place(
        path[matches..],
        @floatFromInt(coords[0] + config.text.getSize(path[0..matches])),
        @floatFromInt(coords[1]),
        .color,
        output.egl.text_shader_program,
    );
}

pub fn updateCoordinates(
    self: *Self,
    config: *Config,
    border_mode: bool,
    outputs: *[]Output,
    buffer: *std.ArrayList(u32),
) void {
    var intersections = std.ArrayList([2]i32).init(self.arena.allocator());
    defer intersections.deinit();

    for (outputs.*) |output| {
        const info = output.info;

        if (border_mode) {
            intersections.appendSlice(&[_][2]i32{
                .{ info.x, info.y },
                .{ info.x, info.y + info.height - 1 },
                .{ info.x + info.width - 1, info.y },
                .{ info.x + info.width - 1, info.y + info.height - 1 },
            }) catch @panic("OOM");
            continue;
        }

        const vert_line_count = @divFloor(info.x, config.grid.size[0]);
        const hor_line_count = @divFloor(info.y, config.grid.size[1]);

        var start_pos: [2]i32 = .{
            vert_line_count * config.grid.size[0] + config.grid.offset[0],
            hor_line_count * config.grid.size[1] + config.grid.offset[1],
        };

        if (start_pos[0] < output.info.x) start_pos[0] += config.grid.size[0];
        if (start_pos[1] < output.info.y) start_pos[1] += config.grid.size[1];

        var i = start_pos[0];
        while (i <= info.x + info.width - 1) : (i += config.grid.size[0]) {
            var j = start_pos[1];
            while (j <= info.y + info.height - 1) : (j += config.grid.size[1]) {
                intersections.append(.{ i, j }) catch @panic("OOM");
            }
        }
    }

    const depth: u8 = depth: {
        const items_len: f64 = @floatFromInt(intersections.items.len);
        const keys_len: f64 = @floatFromInt(self.keys.len);
        const depth = std.math.log(f64, keys_len, items_len);
        break :depth @intFromFloat(std.math.ceil(depth));
    };

    var char_size: i32 = 0;
    for (config.text.char_info) |char| {
        const scale = config.font.size / 256.0;
        const size: f32 = @floatFromInt(char.advance[0]);

        const final_size: i32 = @intFromFloat(size * scale);

        if (final_size > char_size) char_size = final_size;
    }

    config.*.grid.max_size[0] = char_size * (depth + 1) + config.font.offset[0];

    if (depth < self.depth) {
        for (depth..self.depth) |_| self.decreaseDepth();
        buffer.clearAndFree();
    } else if (depth > self.depth) {
        for (self.depth..depth) |_| self.increaseDepth();
        buffer.clearAndFree();
    }

    var index: usize = 0;
    for (self.children) |*child| {
        child.updateCoordinates(intersections.items, &index);
    }
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
    coordinates: ?[2]i32 = null,

    fn checkIfOnScreen(self: *Node) !void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return error.KeyNotFound;
                return child.checkIfOnScreen();
            }
        }
    }

    fn find(self: *Node, buffer: *[]u32, index: usize) ![2]i32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (self.children == null) return error.KeyNotFound;
        if (buffer.*.len <= index) {
            try self.checkIfOnScreen();
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
                } else {
                    child.drawText(config, path, index + 1, output, buffer, border_mode);
                }
            }
        }
    }

    fn updateCoordinates(self: *Node, intersections: [][2]i32, index: *usize) void {
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
