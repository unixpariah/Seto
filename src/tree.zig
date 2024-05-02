const std = @import("std");

pub const Tree = struct {
    tree: std.StringHashMap(Node),
    alloc: std.mem.Allocator,
    pub fn new(alloc: std.mem.Allocator, keys: [9]*const [1:0]u8, depth: usize, crosses: *std.ArrayList([2]usize)) !Tree {
        return .{ .tree = try createNestedTree(alloc, keys, depth, crosses), .alloc = alloc };
    }
};

const Node = union(enum) {
    node: std.StringHashMap(Node),
    position: ?[2]usize,
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
