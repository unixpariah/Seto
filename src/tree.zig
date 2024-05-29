const std = @import("std");
const cairo = @import("cairo");
const Font = @import("config.zig").Font;
const Seto = @import("main.zig").Seto;
const Grid = @import("config.zig").Grid;
const Mode = @import("main.zig").Mode;
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

        var rect: pango.Rectangle = undefined;
        var logical_rect: pango.Rectangle = undefined;
        layout.getExtents(&rect, &logical_rect);
        ctx.relMoveTo(@as(f64, @floatFromInt(logical_rect.width)) / pango.SCALE, 0);
        ctx.setSourceRgba(font.color[0], font.color[1], font.color[2], font.color[3]);
    }

    layout.setText(path[matches..path.len]);
    ctx.showLayout(layout);
}

pub const Tree = struct {
    children: []Node,
    keys: []const u8,
    dimensions: [2]i32,
    depth: u8,
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(keys: []const u8, alloc: std.mem.Allocator, dimensions: [2]i32, grid: Grid, mode: Mode) Self {
        var arena = std.heap.ArenaAllocator.init(alloc);
        const nodes = arena.allocator().alloc(Node, keys.len) catch @panic("OOM");
        for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };

        const intersections = intersections: {
            const width: u32 = @intCast(dimensions[0]);
            const height: u32 = @intCast(dimensions[1]);

            const num_steps_i = @divTrunc((width - grid.offset[0]), grid.size[0]) + 1;
            const num_steps_j = @divTrunc((height - grid.offset[1]), grid.size[1]) + 1;

            const total_intersections = num_steps_i * num_steps_j;

            var intersections = arena.allocator().alloc([2]isize, @intCast(total_intersections)) catch @panic("OOM");

            var index: usize = 0;
            var i = grid.offset[0];
            while (i <= width) : (i += grid.size[0]) {
                var j = grid.offset[1];
                while (j <= height) : (j += grid.size[1]) {
                    intersections[index] = .{ i, j };
                    index += 1;
                }
            }

            break :intersections intersections;
        };

        const max_depth: u8 = depth: {
            const items_len: f64 = @floatFromInt(intersections.len);
            const keys_len: f64 = @floatFromInt(keys.len);
            const depth = std.math.log(f64, keys_len, items_len);
            break :depth @intFromFloat(std.math.ceil(depth));
        };

        var tree = Self{
            .children = nodes,
            .keys = keys,
            .dimensions = dimensions,
            .depth = 1,
            .arena = arena,
        };

        for (1..max_depth) |_| {
            tree.increaseDepth();
        }

        tree.putCoordinates(intersections, mode);

        return tree;
    }

    pub fn drawText(self: *Self, ctx: *cairo.Context, font: Font, buffer: [][64]u8) void {
        const layout: *pango.Layout = ctx.createLayout() catch @panic("OOM");
        defer layout.destroy();
        const font_description = pango.FontDescription.new() catch @panic("OOM");
        defer font_description.free();

        font_description.setFamilyStatic(font.family);
        font_description.setStyle(font.style);
        font_description.setWeight(font.weight);
        font_description.setAbsoluteSize(font.size * pango.SCALE);
        font_description.setVariant(font.variant);
        font_description.setStretch(font.stretch);
        font_description.setGravity(font.gravity);

        layout.setFontDescription(font_description);

        ctx.setSourceRgba(font.color[0], font.color[1], font.color[2], font.color[3]);

        const path = self.arena.allocator().alloc(u8, self.depth) catch @panic("OOM");

        for (self.children) |*child| {
            path[0] = child.key;
            const matches: u8 = if (buffer.len > 0 and buffer[0][0] == child.key) 1 else 0;
            if (child.children) |_| {
                child.traverseAndDraw(ctx, buffer, font, path, matches, 1, layout);
            } else {
                cairoDraw(ctx, child.coordinates.?, path, matches, font, layout);
            }
        }
    }

    pub fn find(self: *Self, buffer: [][64]u8) ![2]isize {
        if (buffer.len == 0) return error.EndNotReached;
        for (self.children) |*child| {
            if (child.key == buffer[0][0]) {
                return child.traverseAndFind(buffer, 1);
            }
        }

        return error.KeyNotFound;
    }

    fn putCoordinates(self: *Self, intersections: [][2]isize, mode: Mode) void {
        var index: usize = 0;
        for (self.children) |*child| {
            child.traverseAndPutCoords(intersections, &index, mode);
        }
    }

    fn increaseDepth(self: *Self) void {
        self.depth += 1;
        for (self.children) |*child| {
            child.traverseAndCreateChildren(self.keys, self.arena.allocator());
        }
    }

    fn decreaseDepth(self: *Self) void {
        self.depth -= 1;
        for (self.children) |*child| {
            child.traverseAndFreeChildren(self.keys, self.arena.allocator());
        }
    }
};

const Node = struct {
    key: u8,
    children: ?[]Node = null,
    coordinates: ?[2]isize = null,

    const Self = @This();

    fn traverseAndDraw(self: *Self, ctx: *cairo.Context, buffer: [][64]u8, font: Font, path: []u8, matches: u8, index: u8, layout: *pango.Layout) void {
        if (self.children) |children| {
            for (children) |*child| {
                const match = if (matches == index and buffer.len > index and buffer[index][0] == child.key) matches + 1 else if (buffer.len > index) 0 else matches;

                path[index] = child.key;

                if (child.coordinates) |coordinates| {
                    cairoDraw(ctx, coordinates, path, match, font, layout);
                } else {
                    child.traverseAndDraw(ctx, buffer, font, path, match, index + 1, layout);
                }
            }
        }
    }

    fn traverseAndFind(self: *Self, buffer: [][64]u8, index: usize) ![2]isize {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.len <= index) return error.EndNotReached;
        if (self.children) |children| {
            for (children) |*child| {
                if (child.key == buffer[index][0]) {
                    return child.traverseAndFind(buffer, index + 1);
                }
            }
        }

        return error.KeyNotFound;
    }

    fn traverseAndPutCoords(self: *Self, intersections: [][2]isize, index: *usize, mode: Mode) void {
        if (self.children == null) {
            if (index.* < intersections.len) {
                self.coordinates = intersections[index.*];
                index.* += 1;
            }
        } else {
            for (self.children.?) |*child| {
                child.traverseAndPutCoords(intersections, index, mode);
            }
        }
    }

    fn traverseAndCreateChildren(self: *Self, keys: []const u8, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| child.traverseAndCreateChildren(keys, alloc);
        } else {
            self.createChildren(keys, alloc);
        }
    }

    fn traverseAndFreeChildren(self: *Self, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |child| child.traverseAndFreeChildren();
        } else {
            alloc.free(self);
        }
    }

    fn createChildren(self: *Self, keys: []const u8, alloc: std.mem.Allocator) void {
        if (self.children == null) {
            const nodes = alloc.alloc(Node, keys.len) catch @panic("OOM");
            for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };
            self.children = nodes;
        }
    }
};

test "new_tree" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    const keys = "asdfghjkl";
    const tree = Tree.new(keys, alloc, .{ 1920, 1080 }, Grid{});
    assert(tree.children.len == keys.len);
    assert(tree.depth == 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    const bigger_tree = Tree.new(keys, alloc, .{ 5000, 5000 }, Grid{});
    assert(bigger_tree.children.len == keys.len);
    assert(bigger_tree.depth > 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    const smaller_tree = Tree.new(keys, alloc, .{ 500, 500 }, Grid{});
    assert(smaller_tree.children.len == keys.len);
    assert(smaller_tree.depth < 3);

    for (tree.children, 0..) |node, i| {
        assert(node.key == tree.keys[i]);
    }

    for (0..3) |i| { // Testing only 3 because some positions can be null
        var node = tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);

        node = bigger_tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);

        node = smaller_tree.children[i];
        while (node.children) |children| : (node = children[i]) {}
        assert(node.coordinates != null);
    }
}

test "find" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    const keys = "asdfghjkl";
    var tree = Tree.new(keys, alloc, .{ 1920, 1080 }, Grid{});
    var buffer: [0][64]u8 = undefined;
    _ = tree.find(&buffer) catch |err| assert(err == error.EndNotReached);

    var buffer_2: [1][64]u8 = undefined;
    buffer_2[0][0] = 1;
    _ = tree.find(&buffer_2) catch |err| assert(err == error.KeyNotFound);

    var buffer_3: [3][64]u8 = undefined;
    buffer_3[0][0] = 97;
    buffer_3[1][0] = 97;
    buffer_3[2][0] = 97;
    var positions = tree.find(&buffer_3) catch @panic("");
    assert(positions[0] == 0 and positions[1] == 0);

    buffer_3 = undefined;
    buffer_3[0][0] = 97;
    buffer_3[1][0] = 97;
    buffer_3[2][0] = 115;
    positions = tree.find(&buffer_3) catch @panic("");
    assert(positions[0] == 0 and positions[1] == 80);
}
