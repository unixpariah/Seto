const std = @import("std");

const Result = struct {
    path: [:0]const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    tree: std.StringHashMap(Node),
    alloc: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const *const [1:0]u8, depth: usize, intersections: *std.ArrayList([2]usize)) !Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        return .{ .tree = try createNestedTree(a_alloc.allocator(), keys, depth, intersections), .alloc = a_alloc };
    }

    pub fn find(self: *Self, keys: [][64]u8) void {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0..1]);
            if (node) |n| {
                if (n.traverse(keys[1..keys.len])) |result| {
                    const positions = std.fmt.allocPrintZ(self.alloc.allocator(), "{},{}\n", .{ result[0], result[1] }) catch return;
                    _ = std.io.getStdOut().write(positions) catch |err| std.debug.panic("{}", .{err});
                    std.process.exit(0);
                }
            }
        }
    }

    pub fn iter(self: *Self, keys: []const *const [1:0]u8) ![](Result) {
        var arr = std.ArrayList(Result).init(self.alloc.allocator());
        for (keys) |key| {
            if (self.tree.get(key)) |node| try node.collect(self.alloc.allocator(), keys, key, &arr);
        }

        return try arr.toOwnedSlice();
    }
};

const Node = union(enum) {
    node: std.StringHashMap(Node),
    position: ?[2]usize,

    const Self = @This();

    fn traverse(self: *const Self, keys: [][64]u8) ?[2]usize {
        switch (self.*) {
            .node => |node| {
                if (keys.len > 0) {
                    if (node.get(keys[0][0..1])) |n| return n.traverse(keys[1..keys.len]);
                }
            },
            .position => |pos| return pos,
        }
        return null;
    }

    fn collect(self: *const Self, alloc: std.mem.Allocator, keys: []const *const [1:0]u8, path: [:0]const u8, result: *std.ArrayList(Result)) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    const new_path = try std.fmt.allocPrintZ(alloc, "{s}{s}", .{ path, key });
                    try node.get(key).?.collect(alloc, keys, new_path, result);
                },
                .position => |position| {
                    const pos = position orelse return;
                    try result.append(.{ .pos = pos, .path = path });
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
