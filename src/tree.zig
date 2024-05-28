const std = @import("std");
const cairo = @import("cairo");
const Font = @import("config.zig").Font;
const Seto = @import("main.zig").Seto;
const pango = @import("pango");

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

fn cairoDraw(ctx: *cairo.Context, position: [2]isize, path: []u8, matches: u8, font: Font, layout: *pango.Layout) void {
    ctx.moveTo(@floatFromInt(position[0] + font.offset[0]), @floatFromInt(position[1] + font.offset[1]));
    if (matches > 0) {
        ctx.setSourceRgba(font.highlight_color[0], font.highlight_color[1], font.highlight_color[2], font.highlight_color[3]);
        layout.setText(path[0..matches]);
        ctx.showLayout(layout);

        var logical_rect: pango.Rectangle = undefined;
        layout.getExtents(undefined, &logical_rect);
        ctx.relMoveTo(@as(f64, @floatFromInt(logical_rect.width)) / pango.SCALE, 0);
        ctx.setSourceRgba(font.color[0], font.color[1], font.color[2], font.color[3]);
    }

    layout.setText(path[matches..path.len]);
    ctx.showLayout(layout);
}

pub const Tree = struct {
    tree: std.AutoHashMap(u8, Node),
    alloc: std.heap.ArenaAllocator,
    depth: u8,
    keys: []const u8,

    const Self = @This();

    pub fn new(alloc: std.mem.Allocator, keys: []const u8, depth: u8, intersections: [][2]isize) Self {
        var a_alloc = std.heap.ArenaAllocator.init(alloc);
        var tree_index: usize = 0;
        const tree = createNestedTree(a_alloc.allocator(), keys, depth, intersections, &tree_index);
        return .{ .tree = tree, .alloc = a_alloc, .keys = keys, .depth = depth };
    }

    pub fn find(self: *Self, keys: [][64]u8) ![2]isize {
        if (keys.len > 0) {
            const node = self.tree.get(keys[0][0]) orelse return error.KeyNotFound;
            const result = try node.traverse(keys[1..keys.len]);
            return result;
        }
        return error.EndNotReached;
    }

    pub fn drawText(self: *Self, ctx: *cairo.Context, font: Font, buffer: [][64]u8) void {
        var path = self.alloc.child_allocator.alloc(u8, self.depth) catch @panic("OOM");
        defer self.alloc.child_allocator.free(path);

        var iterator = self.tree.iterator();
        while (iterator.next()) |node| {
            const key = node.key_ptr.*;
            path[0] = key;
            const matches: u8 = if (buffer.len > 0 and buffer[0][0] == key) 1 else 0;
            const layout: *pango.Layout = ctx.createLayout() catch @panic("");
            defer layout.destroy();
            const font_description = pango.FontDescription.new() catch @panic("");
            defer font_description.free();

            font_description.setFamilyStatic(font.family);
            font_description.setStyle(font.slant);
            font_description.setWeight(font.weight);
            font_description.setAbsoluteSize(font.size * pango.SCALE);

            layout.setFontDescription(font_description);

            ctx.setSourceRgba(font.color[0], font.color[1], font.color[2], font.color[3]);
            switch (node.value_ptr.*) {
                .position => |position| cairoDraw(ctx, position, path, matches, font, layout),
                .node => node.value_ptr.traverseAndRender(self.keys, path, ctx, buffer, 1, matches, font, layout),
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

    fn traverseAndRender(self: *const Self, keys: []const u8, path: []u8, ctx: *cairo.Context, buffer: [][64]u8, index: u8, matches: u8, font: Font, layout: *pango.Layout) void {
        for (keys) |key| {
            switch (self.*) {
                .node => |node| {
                    path[index] = key;
                    if (node.get(key)) |n| {
                        const match = if (matches == index and buffer.len > index and buffer[index][0] == key) matches + 1 else if (buffer.len > index) 0 else matches;
                        n.traverseAndRender(keys, path, ctx, buffer, index + 1, match, font, layout);
                    }
                },
                .position => |position| {
                    cairoDraw(ctx, position, path, matches, font, layout);
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
