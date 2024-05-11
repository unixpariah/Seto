const std = @import("std");

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    tree: std.AutoHashMap(u8, Node),
    alloc: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        var tree_index: usize = 0;
        const tree = createNestedTree(a_alloc.allocator(), keys, depth, intersections, &tree_index);
        return .{ .tree = tree, .alloc = a_alloc };
    }

    pub fn find(self: *Self, keys: [][64]u8) !void {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0]) orelse return error.KeyNotFound;
            const result = try node.traverse(keys[1..keys.len]);
            const positions = std.fmt.allocPrintZ(self.alloc.allocator(), "{},{}\n", .{ result[0], result[1] }) catch return;
            _ = std.io.getStdOut().write(positions) catch |err| std.debug.panic("{}", .{err});
            std.process.exit(0);
        }
    }

    pub fn iter(self: *Self, keys: []const u8) ![](Result) {
        var arr = std.ArrayList(Result).init(self.alloc.allocator());
        for (keys) |key| {
            var nt_key: [1]u8 = undefined;
            nt_key[0] = key;
            if (self.tree.get(key)) |node| {
                try switch (node) {
                    .position => |pos| if (pos) |nn_pos| arr.append(.{ .pos = nn_pos, .path = &nt_key }),
                    .node => node.collect(self.alloc.allocator(), keys, &nt_key, &arr),
                };
            }
        }

        return try arr.toOwnedSlice();
    }
};

const Node = union(enum) {
    node: std.AutoHashMap(u8, Node),
    position: ?[2]usize,

    const Self = @This();

    fn traverse(self: *const Self, keys: [][64]u8) ![2]usize {
        switch (self.*) {
            .node => |node| {
                if (keys.len > 0) {
                    const n = node.get(keys[0][0]) orelse return error.KeyNotFound;
                    return n.traverse(keys[1..keys.len]);
                }
            },
            .position => |pos| if (pos) |p| return p,
        }
        return error.EndNotReached;
    }

    fn collect(self: *const Self, alloc: std.mem.Allocator, keys: []const u8, path: []const u8, result: *std.ArrayList(Result)) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    var new_key: [1]u8 = undefined;
                    new_key[0] = key;
                    const new_path = try std.fmt.allocPrint(alloc, "{s}{s}", .{ path, new_key });
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

fn createNestedTree(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize, tree_index: *usize) std.AutoHashMap(u8, Node) {
    var tree = std.AutoHashMap(u8, Node).init(alloc);

    for (keys) |key| {
        if (depth <= 1) {
            const position = block: {
                if (tree_index.* < intersections.len) break :block intersections[tree_index.*] else break :block null;
            };
            tree.put(key, .{ .position = position }) catch |err| std.debug.panic("{}", .{err});
            tree_index.* += 1;
        } else {
            const new_tree = createNestedTree(alloc, keys, depth - 1, intersections, tree_index);
            tree.put(key, .{ .node = new_tree }) catch |err| std.debug.panic("{}", .{err});
        }
    }

    return tree;
}
