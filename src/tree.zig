const std = @import("std");
const cairo = @import("cairo");
const Font = @import("config.zig").Font;

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

fn drawText(ctx: *cairo.Context, font: Font, position: [2]usize, path: []u8, matches: u8) void {
    ctx.moveTo(@floatFromInt(position[0] + 5), @floatFromInt(position[1] + 15));
    ctx.selectFontFace(font.family, font.slant, font.weight);
    ctx.setFontSize(font.size);

    for (path, 0..) |char, i| {
        ctx.setSourceRgb(font.color[0], font.color[1], font.color[2]);
        if (i < matches) {
            ctx.setSourceRgb(font.highlight_color[0], font.highlight_color[1], font.highlight_color[2]);
        }
        const a: [2]u8 = .{ char, 0 };
        ctx.showText(a[0..1 :0]);
    }
}

pub const Tree = struct {
    tree: std.AutoHashMap(u8, Node),
    alloc: std.heap.ArenaAllocator,
    keys: []const u8,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        var tree_index: usize = 0;
        const tree = createNestedTree(a_alloc.allocator(), keys, depth, intersections, &tree_index);
        return .{ .tree = tree, .alloc = a_alloc, .keys = keys };
    }

    pub fn updateCoords(self: *Self, offset: [2]usize) void {
        for (self.keys) |key| {
            if (self.tree.getPtr(key)) |node| {
                switch (node.*) {
                    .position => |*position| {
                        position[0] += offset[0];
                        position[1] += offset[1];
                    },
                    .node => node.updateCoords(self.keys, offset),
                }
            }
        }
    }

    pub fn find(self: *Self, keys: [][64]u8) !bool {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0]) orelse return error.KeyNotFound;
            const result = try node.traverse(keys[1..keys.len]);
            const positions = std.fmt.allocPrintZ(self.alloc.allocator(), "{},{}\n", .{ result[0], result[1] }) catch return false;
            _ = std.io.getStdOut().write(positions) catch |err| std.debug.panic("{}", .{err});
            return true;
        }
        return false;
    }

    // TODO: how tf do I name it
    pub fn iter(self: *Self, ctx: *cairo.Context, font: Font, buffer: [][64]u8, depth: usize) !void {
        var path = try self.alloc.child_allocator.alloc(u8, depth);
        defer self.alloc.child_allocator.free(path);

        for (self.keys) |key| {
            if (self.tree.get(key)) |node| {
                path[0] = key;
                const matches: u8 = if (buffer.len > 0 and buffer[0][0] == key) 1 else 0;
                try switch (node) {
                    .position => |position| drawText(ctx, font, position, path, matches),
                    .node => node.collect(self.keys, path, ctx, buffer, font, 1, matches),
                };
            }
        }
    }
};

const Node = union(enum) {
    node: std.AutoHashMap(u8, Node),
    position: [2]usize,

    const Self = @This();

    fn traverse(self: *const Self, keys: [][64]u8) ![2]usize {
        switch (self.*) {
            .node => |node| {
                if (keys.len > 0) {
                    const n = node.get(keys[0][0]) orelse return error.KeyNotFound;
                    return n.traverse(keys[1..keys.len]);
                }
            },
            .position => |pos| return pos,
        }
        return error.EndNotReached;
    }

    // TODO: how tf do I name it
    fn collect(self: *const Self, keys: []const u8, path: []u8, ctx: *cairo.Context, buffer: [][64]u8, font: Font, index: u8, matches: u8) !void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    path[index] = key;
                    if (node.get(key)) |n| {
                        const m = if (matches == index and buffer.len > index and buffer[index][0] == key) matches + 1 else if (buffer.len > index) 0 else matches;
                        try n.collect(keys, path, ctx, buffer, font, index + 1, m);
                    }
                },
                .position => |position| {
                    drawText(ctx, font, position, path, matches);
                    break;
                },
            }
        }
    }
};

fn createNestedTree(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize, tree_index: *usize) std.AutoHashMap(u8, Node) {
    var tree = std.AutoHashMap(u8, Node).init(alloc);
    for (keys) |key| {
        if (tree_index.* >= intersections.len) break;
        if (depth <= 1) {
            tree.put(key, .{ .position = intersections[tree_index.*] }) catch |err| std.debug.panic("{}", .{err});
            tree_index.* += 1;
        } else {
            const new_tree = createNestedTree(alloc, keys, depth - 1, intersections, tree_index);
            tree.put(key, .{ .node = new_tree }) catch |err| std.debug.panic("{}", .{err});
        }
    }

    return tree;
}
