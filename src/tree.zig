const std = @import("std");
const cairo = @import("cairo");
const Font = @import("config.zig").Font;
const Mode = @import("main.zig").Mode;
const Seto = @import("main.zig").Seto;

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

fn cairoDraw(ctx: *cairo.Context, font: Font, position: [2]isize, path: []u8, matches: u8, text_offset: [2]isize) void {
    ctx.moveTo(@floatFromInt(position[0] + text_offset[0]), @floatFromInt(position[1] + text_offset[1]));

    for (0..matches) |i| {
        ctx.setSourceRgb(font.highlight_color[0], font.highlight_color[1], font.highlight_color[2]);
        ctx.showText(&[2:0]u8{ path[i], 0 });
    }

    path[path.len - 1] = 0;
    ctx.setSourceRgb(font.color[0], font.color[1], font.color[2]);
    ctx.showText(path[matches .. path.len - 1 :0]);
}

pub const Tree = struct {
    tree: std.AutoHashMap(u8, Node),
    alloc: std.heap.ArenaAllocator,
    keys: []const u8,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]isize) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        var tree_index: usize = 0;
        const tree = createNestedTree(a_alloc.allocator(), keys, depth, intersections, &tree_index);
        return .{ .tree = tree, .alloc = a_alloc, .keys = keys };
    }

    pub fn find(self: *Self, keys: [][64]u8) ![2]isize {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0]) orelse return error.KeyNotFound;
            const result = try node.traverse(keys[1..keys.len]);
            return result;
        }
        return error.EndNotReached;
    }

    pub fn drawText(self: *Self, ctx: *cairo.Context, font: Font, buffer: [][64]u8, depth: usize, text_offset: [2]isize) void {
        ctx.selectFontFace(font.family, font.slant, font.weight);
        ctx.setFontSize(font.size);

        var path = self.alloc.child_allocator.alloc(u8, depth + 1) catch @panic("OOM");
        defer self.alloc.child_allocator.free(path);

        var iterator = self.tree.iterator();
        while (iterator.next()) |node| {
            const key = node.key_ptr.*;
            path[0] = key;
            const matches: u8 = if (buffer.len > 0 and buffer[0][0] == key) 1 else 0;
            switch (node.value_ptr.*) {
                .position => |position| cairoDraw(ctx, font, position, path, matches, text_offset),
                .node => node.value_ptr.traverseAndRender(self.keys, path, ctx, buffer, font, 1, matches, text_offset),
            }
        }
    }
};

const Node = union(enum) {
    node: std.AutoHashMap(u8, Node),
    position: [2]isize,

    const Self = @This();

    fn traverse(self: *const Self, keys: [][64]u8) ![2]isize {
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

    fn traverseAndRender(self: *const Self, keys: []const u8, path: []u8, ctx: *cairo.Context, buffer: [][64]u8, font: Font, index: u8, matches: u8, text_offset: [2]isize) void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    path[index] = key;
                    if (node.get(key)) |n| {
                        const match = if (matches == index and buffer.len > index and buffer[index][0] == key) matches + 1 else if (buffer.len > index) 0 else matches;
                        n.traverseAndRender(keys, path, ctx, buffer, font, index + 1, match, text_offset);
                    }
                },
                .position => |position| {
                    cairoDraw(ctx, font, position, path, matches, text_offset);
                    break;
                },
            }
        }
    }
};

fn createNestedTree(alloc: std.mem.Allocator, keys: []const u8, depth: usize, intersections: [][2]isize, tree_index: *usize) std.AutoHashMap(u8, Node) {
    var tree = std.AutoHashMap(u8, Node).init(alloc);
    for (keys) |key| {
        if (tree_index.* >= intersections.len) return tree;
        if (depth <= 1) {
            tree.put(key, .{ .position = intersections[tree_index.*] }) catch @panic("OOM");
            tree_index.* += 1;
            continue;
        }
        const new_tree = createNestedTree(alloc, keys, depth - 1, intersections, tree_index);
        tree.put(key, .{ .node = new_tree }) catch @panic("OOM");
    }

    return tree;
}
