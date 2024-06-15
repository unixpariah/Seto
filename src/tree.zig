const std = @import("std");

const Font = @import("config.zig").Font;
const Seto = @import("main.zig").Seto;
const Surface = @import("surface.zig").Surface;
const Grid = @import("config.zig").Grid;
const Mode = @import("main.zig").Mode;

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    children: []Node,
    keys: []const u8,
    dimensions: [2]i32,
    depth: u8,
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(keys: []const u8, alloc: std.mem.Allocator, dimensions: [2]i32, grid: Grid, outputs: []Surface) Self {
        var arena = std.heap.ArenaAllocator.init(alloc);
        const nodes = arena.allocator().alloc(Node, keys.len) catch @panic("OOM");
        for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };

        var tree = Self{
            .children = nodes,
            .keys = keys,
            .dimensions = dimensions,
            .depth = 1,
            .arena = arena,
        };

        var tmp = std.ArrayList([64]u8).init(alloc);
        tree.updateCoordinates(dimensions, grid, false, outputs, &tmp);

        return tree;
    }

    pub fn find(self: *Self, buffer: [][64]u8) ![2]i32 {
        if (buffer.len == 0) return error.EndNotReached;
        for (self.children) |*child| {
            if (child.key == buffer[0][0]) {
                return child.traverseAndFind(buffer, 1);
            }
        }

        return error.KeyNotFound;
    }

    pub fn updateCoordinates(self: *Self, dimensions: [2]i32, grid: Grid, border_mode: bool, outputs: []Surface, buffer: *std.ArrayList([64]u8)) void {
        const intersections = intersections: {
            if (!border_mode) {
                const width = dimensions[0];
                const height = dimensions[1];

                const num_steps_i = @divTrunc((width - grid.offset[0]), grid.size[0]) + 1;
                const num_steps_j = @divTrunc((height - grid.offset[1]), grid.size[1]) + 1;

                const total_intersections = num_steps_i * num_steps_j;

                var intersections = self.arena.allocator().alloc([2]i32, @intCast(total_intersections)) catch @panic("OOM");

                var index: usize = 0;
                var i = grid.offset[0];
                while (i <= width - 1) : (i += grid.size[0]) {
                    var j = grid.offset[1];
                    while (j <= height - 1) : (j += grid.size[1]) {
                        intersections[index] = .{ i, j };
                        index += 1;
                    }
                }

                break :intersections intersections;
            } else {
                var intersections = std.ArrayList([2]i32).init(self.arena.allocator());

                var pos: [2]i32 = .{ 0, 0 };

                var index: u8 = 0;
                while (index < outputs.len) : (index += 1) {
                    if (!outputs[index].isConfigured()) continue;
                    const info = outputs[index].output_info;

                    if (index > 0) {
                        if (info.x <= outputs[index - 1].output_info.x) pos = .{ 0, outputs[index - 1].output_info.height };
                    }

                    intersections.append(pos) catch unreachable;
                    intersections.append(.{ pos[0], pos[1] + info.height - 1 }) catch unreachable;
                    intersections.append(.{ pos[0] + info.width - 1, pos[1] }) catch unreachable;
                    intersections.append(.{ pos[0] + info.width - 1, pos[1] + info.height - 1 }) catch unreachable;

                    pos[0] += info.width;
                }

                break :intersections intersections.toOwnedSlice() catch @panic("OOM");
            }
        };
        defer self.arena.allocator().free(intersections);

        const depth: u8 = depth: {
            const items_len: f64 = @floatFromInt(intersections.len);
            const keys_len: f64 = @floatFromInt(self.keys.len);
            const depth = std.math.log(f64, keys_len, items_len);
            break :depth @intFromFloat(std.math.ceil(depth));
        };

        if (depth < self.depth) {
            for (depth..self.depth) |_| {
                self.decreaseDepth();
                buffer.clearAndFree();
            }
        } else if (depth > self.depth) {
            for (self.depth..depth) |_| {
                self.increaseDepth();
                buffer.clearAndFree();
            }
        }

        var index: usize = 0;
        for (self.children) |*child| {
            child.traverseAndPutCoords(intersections, &index);
        }
    }

    fn increaseDepth(self: *Self) void {
        self.depth += 1;
        for (self.children) |*child| {
            child.traverseAndCreateChildren(self.keys, self.arena.allocator());
        }
    }

    fn decreaseDepth(self: *Self) void {
        self.depth -= 1;
        for (self.children) |*child| {
            child.traverseAndFreeChildren(self.arena.allocator());
        }
    }
};

const Node = struct {
    key: u8,
    children: ?[]Node = null,
    coordinates: ?[2]i32 = null,

    const Self = @This();

    fn checkIfOnScreen(self: *Self) !void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return error.KeyNotFound;
                return child.checkIfOnScreen();
            }
        }
    }

    fn traverseAndFind(self: *Self, buffer: [][64]u8, index: usize) ![2]i32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.len <= index) {
            try self.checkIfOnScreen();
            return error.EndNotReached;
        }
        if (self.children) |children| {
            for (children) |*child| {
                if (child.key == buffer[index][0]) {
                    return child.traverseAndFind(buffer, index + 1);
                }
            }
        }

        return error.KeyNotFound;
    }

    fn traverseAndPutCoords(self: *Self, intersections: [][2]i32, index: *usize) void {
        if (self.children == null) {
            if (index.* < intersections.len) {
                self.coordinates = intersections[index.*];
                index.* += 1;
            } else {
                self.coordinates = null;
            }
        } else {
            for (self.children.?) |*child| {
                child.traverseAndPutCoords(intersections, index);
            }
        }
    }

    fn traverseAndCreateChildren(self: *Self, keys: []const u8, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| child.traverseAndCreateChildren(keys, alloc);
        } else {
            self.createChildren(keys, alloc);
        }
    }

    fn traverseAndFreeChildren(self: *Self, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null) {
                    alloc.free(self.children.?);
                    self.children = null;
                    return;
                } else {
                    child.traverseAndFreeChildren(alloc);
                }
            }
        }
    }

    fn createChildren(self: *Self, keys: []const u8, alloc: std.mem.Allocator) void {
        self.coordinates = null;
        if (self.children == null) {
            const nodes = alloc.alloc(Node, keys.len) catch @panic("OOM");
            for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };
            self.children = nodes;
        }
    }
};

test "new_tree" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    const keys = "asdfghjkl";
    const tree = Tree.new(keys, alloc, .{ 1920, 1080 }, Grid{});
    assert(tree.children.len == keys.len);
    assert(tree.depth == 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    const bigger_tree = Tree.new(keys, alloc, .{ 5000, 5000 }, Grid{});
    assert(bigger_tree.children.len == keys.len);
    assert(bigger_tree.depth > 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    const smaller_tree = Tree.new(keys, alloc, .{ 500, 500 }, Grid{});
    assert(smaller_tree.children.len == keys.len);
    assert(smaller_tree.depth < 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    for (0..3) |i| { // Testing only 3 because some positions can be null
        var node = tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);

        node = bigger_tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);

        node = smaller_tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);
    }
}

test "find" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    const keys = "asdfghjkl";
    var tree = Tree.new(keys, alloc, .{ 1920, 1080 }, Grid{});
    var buffer: [0][64]u8 = undefined;
    _ = tree.find(&buffer) catch |err| assert(err == error.EndNotReached);

    var buffer_2: [1][64]u8 = undefined;
    buffer_2[0][0] = 1;
    _ = tree.find(&buffer_2) catch |err| assert(err == error.KeyNotFound);

    var buffer_3: [3][64]u8 = undefined;
    buffer_3[0][0] = 97;
    buffer_3[1][0] = 97;
    buffer_3[2][0] = 97;
    var positions = tree.find(&buffer_3) catch @panic("");
    assert(positions[0] == 0 and positions[1] == 0);

    buffer_3 = undefined;
    buffer_3[0][0] = 97;
    buffer_3[1][0] = 97;
    buffer_3[2][0] = 115;
    positions = tree.find(&buffer_3) catch @panic("");
    assert(positions[0] == 0 and positions[1] == 80);
}
