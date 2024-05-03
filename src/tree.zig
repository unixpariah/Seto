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

    pub fn iter(self: *const Tree, keys: [9]*const [1:0]u8) ![](Result) {
        var arr = std.ArrayList(Result).init(self.alloc);
        for (keys) |key| {
            if (self.tree.get(key)) |node| _ = try node.traverse(keys, key, &arr);
        }

        return try arr.toOwnedSlice();
    }

    pub fn destroy(self: *Tree) void {
        deinitNodes(&self.tree);
        self.tree.deinit();
    }
};

fn deinitNodes(tree: *std.StringHashMap(Node)) void {
    var it = tree.iterator();
    while (it.next()) |entry| {
        switch (entry.value_ptr.*) {
            .node => |*node| {
                deinitNodes(node);
                node.deinit();
            },
            else => {},
        }
    }
}

const Node = union(enum) {
    node: std.StringHashMap(Node),
    position: ?[2]usize,

    fn traverse(self: *const Node, keys: [9]*const [1:0]u8, path: [:0]const u8, result: *std.ArrayList(Result)) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    const a = try std.fmt.allocPrintZ(std.heap.page_allocator, "{s}{s}", .{ path, key });
                    try node.get(key).?.traverse(keys, a, result);
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

fn createNestedTree(alloc: std.mem.Allocator, keys: [9]*const [1:0]u8, depth: usize, crosses: *std.ArrayList([2]usize)) !std.StringHashMap(Node) {
    var tree = std.StringHashMap(Node).init(alloc);

    for (keys) |key| {
        if (depth <= 1) {
            try tree.put(key, .{ .position = crosses.popOrNull() });
        } else {
            var new_tree = try createNestedTree(alloc, keys, depth - 1, crosses);
            try tree.put(key, .{ .node = new_tree });
        }
    }

    return tree;
}
