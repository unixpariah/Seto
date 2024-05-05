const std = @import("std");

const Result = struct {
    path: [:0]const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    tree: std.StringHashMap(Node),
    alloc: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const *const [1:0]u8, depth: usize, crosses: *std.ArrayList([2]usize)) !Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        return .{ .tree = try createNestedTree(a_alloc.allocator(), keys, depth, crosses), .alloc = a_alloc };
    }

    pub fn iter(self: *Self, keys: []const *const [1:0]u8) ![](Result) {
        var arr = std.ArrayList(Result).init(self.alloc.allocator());
        for (keys) |key| {
            if (self.tree.get(key)) |node| try node.traverse(self.alloc.allocator(), keys, key, &arr);
        }

        return try arr.toOwnedSlice();
    }
};

const Node = union(enum) {
    node: std.StringHashMap(Node),
    position: ?[2]usize,

    const Self = @This();

    fn traverse(self: *const Self, alloc: std.mem.Allocator, keys: []const *const [1:0]u8, path: [:0]const u8, result: *std.ArrayList(Result)) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    const a = try std.fmt.allocPrintZ(alloc, "{s}{s}", .{ path, key });
                    try node.get(key).?.traverse(alloc, keys, a, result);
                },
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

fn createNestedTree(alloc: std.mem.Allocator, keys: []const *const [1:0]u8, depth: usize, intersections: *std.ArrayList([2]usize)) !std.StringHashMap(Node) {
    var tree = std.StringHashMap(Node).init(alloc);

    for (keys) |key| {
        if (depth <= 1) {
            try tree.put(key, .{ .position = intersections.popOrNull() });
        } else {
            var new_tree = try createNestedTree(alloc, keys, depth - 1, intersections);
            try tree.put(key, .{ .node = new_tree });
        }
    }

    return tree;
}
