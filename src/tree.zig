const std = @import("std");

const Result = struct {
    path: [:0]const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    tree: std.StringHashMap(Node),
    alloc: std.mem.Allocator,
    pub fn new(alloc: std.mem.Allocator, keys: [9]*const [1:0]u8, depth: usize, crosses: *std.ArrayList([2]usize)) !Tree {
        return .{ .tree = try createNestedTree(alloc, keys, depth, crosses), .alloc = alloc };
    }

    pub fn iter(self: *const Tree, keys: [9]*const [1:0]u8) ![]const (Result) {
        var arr = std.ArrayList(Result).init(self.alloc);
        for (keys) |key| {
            if (self.tree.get(key)) |node| _ = try node.traverse(keys, key, &arr);
        }

        return arr.items;
    }
};

const Node = union(enum) {
    node: std.StringHashMap(Node),
    position: ?[2]usize,

    fn traverse(self: *const Node, keys: [9]*const [1:0]u8, path: [:0]const u8, result: *std.ArrayList(Result)) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| try node.get(key).?.traverse(keys, key, result),
                .position => |position| {
                    if (position) |pos| {
                        try result.append(.{ .pos = pos, .path = path });
                    }
                    return;
                },
            }
        }
    }
};

fn createNestedTree(allocator: std.mem.Allocator, keys: [9]*const [1:0]u8, depth: usize, crosses: *std.ArrayList([2]usize)) !std.StringHashMap(Node) {
    var tree = std.StringHashMap(Node).init(allocator);

    for (keys) |key| {
        if (depth <= 1) {
            try tree.put(key, .{ .position = crosses.popOrNull() });
        } else {
            var new_tree = try createNestedTree(allocator, keys, depth - 1, crosses);
            try tree.put(key, .{ .node = new_tree });
        }
    }

    return tree;
}
