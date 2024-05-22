const std = @import("std");
const cairo = @import("cairo");
const Font = @import("config.zig").Font;
const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

fn cairoDraw(ctx: *cairo.Context, font: Font, position: [2]usize, path: []u8, matches: u8) void {
    ctx.moveTo(@floatFromInt(position[0] + 5), @floatFromInt(position[1] + 15));
    ctx.selectFontFace(font.family, font.slant, font.weight);
    ctx.setFontSize(font.size);

    for (path, 0..) |char, i| {
        if (i < matches)
            ctx.setSourceRgb(font.highlight_color[0], font.highlight_color[1], font.highlight_color[2])
        else
            ctx.setSourceRgb(font.color[0], font.color[1], font.color[2]);
        ctx.showText(&[2:0]u8{ char, 0 });
    }
}

pub const Tree = struct {
    tree: std.AutoHashMap(u8, Node),
    alloc: std.heap.ArenaAllocator,
    keys: []const u8,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize, ignore_coords: ?[2]usize) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        var tree_index: usize = 0;
        const tree = createNestedTree(a_alloc.allocator(), keys, depth, intersections, &tree_index, ignore_coords);
        return .{ .tree = tree, .alloc = a_alloc, .keys = keys };
    }

    pub fn find(self: *Self, keys: [][64]u8) ![2]usize {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0]) orelse return error.KeyNotFound;
            const result = try node.traverse(keys[1..keys.len]);
            return result;
        }
        return error.EndNotReached;
    }

    pub fn drawText(self: *Self, ctx: *cairo.Context, font: Font, buffer: [][64]u8, depth: usize) void {
        var path = self.alloc.child_allocator.alloc(u8, depth) catch @panic("OOM");
        defer self.alloc.child_allocator.free(path);

        var iterator = self.tree.iterator();
        while (iterator.next()) |node| {
            const key = node.key_ptr.*;
            path[0] = key;
            const matches: u8 = if (buffer.len > 0 and buffer[0][0] == key) 1 else 0;
            switch (node.value_ptr.*) {
                .position => |position| cairoDraw(ctx, font, position, path, matches),
                .node => node.value_ptr.traverseAndRender(self.keys, path, ctx, buffer, font, 1, matches),
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

    fn traverseAndRender(self: *const Self, keys: []const u8, path: []u8, ctx: *cairo.Context, buffer: [][64]u8, font: Font, index: u8, matches: u8) void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    path[index] = key;
                    if (node.get(key)) |n| {
                        const m = if (matches == index and buffer.len > index and buffer[index][0] == key) matches + 1 else if (buffer.len > index) 0 else matches;
                        n.traverseAndRender(keys, path, ctx, buffer, font, index + 1, m);
                    }
                },
                .position => |position| {
                    cairoDraw(ctx, font, position, path, matches);
                    break;
                },
            }
        }
    }
};

fn createNestedTree(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]usize, tree_index: *usize, ignore_coords: ?[2]usize) std.AutoHashMap(u8, Node) {
    var tree = std.AutoHashMap(u8, Node).init(alloc);
    for (keys) |key| {
        if (tree_index.* >= intersections.len) return tree;
        if (depth <= 1) {
            tree.put(key, .{ .position = intersections[tree_index.*] }) catch @panic("OOM");
            tree_index.* += 1;
            continue;
        }
        const new_tree = createNestedTree(alloc, keys, depth - 1, intersections, tree_index, ignore_coords);
        tree.put(key, .{ .node = new_tree }) catch @panic("OOM");
    }

    return tree;
}
