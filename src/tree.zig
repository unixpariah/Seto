const std = @import("std");

const Seto = @import("main.zig").Seto;
const Surface = @import("surface.zig").Surface;
const Grid = @import("config.zig").Grid;
const SurfaceIterator = @import("surface.zig").SurfaceIterator;

pub const Result = struct {
    path: []const u8,
    pos: [2]usize,
};

pub const Tree = struct {
    children: []Node,
    keys: []const u8,
    depth: u8,
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn new(keys: []const u8, alloc: std.mem.Allocator, grid: Grid, outputs: []Surface) Self {
        var arena = std.heap.ArenaAllocator.init(alloc);
        const nodes = arena.allocator().alloc(Node, keys.len) catch @panic("OOM");
        for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };

        var tree = Self{
            .children = nodes,
            .keys = keys,
            .depth = 1,
            .arena = arena,
        };

        var tmp = std.ArrayList([64]u8).init(alloc);
        tree.updateCoordinates(grid, false, outputs, &tmp);

        return tree;
    }

    pub fn find(self: *Self, buffer: [][64]u8) ![2]i32 {
        if (buffer.len == 0) return error.EndNotReached;
        for (self.children) |*child| {
            if (child.key == buffer[0][0]) {
                return child.traverseAndFind(buffer, 1);
            }
        }

        return error.KeyNotFound;
    }

    pub fn updateCoordinates(
        self: *Self,
        grid: Grid,
        border_mode: bool,
        outputs: []Surface,
        buffer: *std.ArrayList([64]u8),
    ) void {
        var intersections = std.ArrayList([2]i32).init(self.arena.allocator());
        defer intersections.deinit();

        var surf_iter = SurfaceIterator.new(outputs);
        var start_pos: [2]?i32 = .{ null, null };
        while (surf_iter.next()) |res| {
            const surf, const position, const new_line = res;
            const info = surf.output_info;

            if (border_mode) {
                intersections.append(position) catch unreachable;
                intersections.append(.{ position[0], position[1] + info.height - 1 }) catch unreachable;
                intersections.append(.{ position[0] + info.width - 1, position[1] }) catch unreachable;
                intersections.append(.{ position[0] + info.width - 1, position[1] + info.height - 1 }) catch unreachable;
                continue;
            }

            var i = if (start_pos[0]) |pos| pos else info.x + grid.offset[0];
            while (i <= position[0] + info.width) : (i += grid.size[0]) {
                var j = if (start_pos[1]) |pos| pos else info.y + grid.offset[1];
                while (j <= position[1] + info.height) : (j += grid.size[1]) {
                    intersections.append(.{ i, j }) catch unreachable;
                }
            }

            start_pos = if (new_line) .{
                null,
                intersections.items[intersections.items.len - 1][0],
            } else .{
                intersections.items[intersections.items.len - 1][1],
                null,
            };
        }

        const depth: u8 = depth: {
            const items_len: f64 = @floatFromInt(intersections.items.len);
            const keys_len: f64 = @floatFromInt(self.keys.len);
            const depth = std.math.log(f64, keys_len, items_len);
            break :depth @intFromFloat(std.math.ceil(depth));
        };

        if (depth < self.depth) {
            for (depth..self.depth) |_| {
                self.decreaseDepth();
                buffer.clearAndFree();
            }
        } else if (depth > self.depth) {
            for (self.depth..depth) |_| {
                self.increaseDepth();
                buffer.clearAndFree();
            }
        }

        var index: usize = 0;
        for (self.children) |*child| {
            child.traverseAndPutCoords(intersections.items, &index);
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
            child.traverseAndFreeChildren(self.arena.allocator());
        }
    }
};

const Node = struct {
    key: u8,
    children: ?[]Node = null,
    coordinates: ?[2]i32 = null,

    const Self = @This();

    fn checkIfOnScreen(self: *Self) !void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return error.KeyNotFound;
                return child.checkIfOnScreen();
            }
        }
    }

    fn traverseAndFind(self: *Self, buffer: [][64]u8, index: usize) ![2]i32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.len <= index) {
            try self.checkIfOnScreen();
            return error.EndNotReached;
        }
        if (self.children) |children| {
            for (children) |*child| {
                if (child.key == buffer[index][0]) {
                    return child.traverseAndFind(buffer, index + 1);
                }
            }
        }

        return error.KeyNotFound;
    }

    fn traverseAndPutCoords(self: *Self, intersections: [][2]i32, index: *usize) void {
        if (self.children == null) {
            if (index.* < intersections.len) {
                self.coordinates = intersections[index.*];
                index.* += 1;
            } else {
                self.coordinates = null;
            }
        } else {
            for (self.children.?) |*child| {
                child.traverseAndPutCoords(intersections, index);
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
            for (children) |*child| {
                if (child.children == null) {
                    alloc.free(self.children.?);
                    self.children = null;
                    return;
                } else {
                    child.traverseAndFreeChildren(alloc);
                }
            }
        }
    }

    fn createChildren(self: *Self, keys: []const u8, alloc: std.mem.Allocator) void {
        self.coordinates = null;
        if (self.children == null) {
            const nodes = alloc.alloc(Node, keys.len) catch @panic("OOM");
            for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };
            self.children = nodes;
        }
    }
};
