const std = @import("std");
const c = @import("ffi");
const helpers = @import("helpers");

const Seto = @import("main.zig").Seto;
const Surface = @import("surface.zig").Surface;
const Grid = @import("config/Grid.zig");
const SurfaceIterator = @import("surface.zig").SurfaceIterator;

children: []Node,
keys: []const u8,
depth: u8,
arena: std.heap.ArenaAllocator,

const Self = @This();

pub fn new(keys: []const u8, alloc: std.mem.Allocator, grid: *const Grid, outputs: *const []Surface) Self {
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

pub fn destroy(self: *const Self) void {
    self.arena.deinit();
}

pub fn find(self: *Self, buffer: *[][64]u8) ![2]i32 {
    if (buffer.len == 0) return error.EndNotReached;
    for (self.children) |*child| {
        if (child.key == buffer.*[0][0]) {
            return child.traverseAndFind(buffer, 1);
        }
    }

    return error.KeyNotFound;
}

pub fn drawText(self: *Self, surface: *const Surface, buffer: [][64]u8, border_mode: bool) void {
    const info = surface.output_info;
    c.glUseProgram(surface.egl.text_shader_program.*);

    const path = self.arena.allocator().alloc(u8, self.depth) catch @panic("OOM");

    for (self.children) |*child| {
        path[0] = child.key;
        if (child.children) |_| {
            child.traverseAndDraw(path, 1, surface, buffer, border_mode);
        } else {
            if (child.coordinates) |coordinates| {
                var matches: u8 = 0;
                for (buffer, 0..) |char, i| {
                    if (path[i] == char[0]) matches += 1 else break;
                }
                if (buffer.len > matches) matches = 0;

                const coords = blk: {
                    if (border_mode) {
                        break :blk if (coordinates[0] == info.x and coordinates[1] == info.y)
                            .{ coordinates[0] + 5, coordinates[1] + 25 }
                        else if (coordinates[0] == info.x and coordinates[1] == info.y + info.height - 1)
                            .{ coordinates[0] + 5, coordinates[1] - 15 }
                        else if (coordinates[0] == info.x + info.width - 1 and coordinates[1] == info.y)
                            break :blk .{ coordinates[0] - 25, coordinates[1] + 25 }
                        else if (coordinates[0] == info.x + info.width - 1 and coordinates[1] == info.y + info.height - 1)
                            break :blk .{ coordinates[0] - 25, coordinates[1] - 15 }
                        else
                            continue;
                    } else {
                        break :blk .{
                            coordinates[0] + surface.config.font.offset[0],
                            coordinates[1] + 20 + surface.config.font.offset[1],
                        };
                    }
                };

                surface.renderText(path, coords[0], coords[1], matches);
            }
        }
    }
}

pub fn updateCoordinates(
    self: *Self,
    grid: *const Grid,
    border_mode: bool,
    outputs: *const []Surface,
    buffer: *std.ArrayList([64]u8),
) void {
    var intersections = std.ArrayList([2]i32).init(self.arena.allocator());
    defer intersections.deinit();

    var surf_iter = SurfaceIterator.new(outputs);
    while (surf_iter.next()) |surface| {
        const info = surface.output_info;

        if (border_mode) {
            intersections.appendSlice(&[_][2]i32{
                .{ info.x, info.y },
                .{ info.x, info.y + info.height - 1 },
                .{ info.x + info.width - 1, info.y },
                .{ info.x + info.width - 1, info.y + info.height - 1 },
            }) catch @panic("OOM");
            continue;
        }

        const vert_line_count = @divFloor(info.x, surface.config.grid.size[0]);
        const hor_line_count = @divFloor(info.y, surface.config.grid.size[1]);

        const start_pos: [2]i32 = .{
            vert_line_count * surface.config.grid.size[0] + surface.config.grid.offset[0],
            hor_line_count * surface.config.grid.size[1] + surface.config.grid.offset[1],
        };

        var i = start_pos[0];
        while (i <= info.x + info.width - 1) : (i += grid.size[0]) {
            var j = start_pos[1];
            while (j <= info.y + info.height - 1) : (j += grid.size[1]) {
                intersections.append(.{ i, j }) catch @panic("OOM");
            }
        }
    }

    const depth: u8 = depth: {
        const items_len: f64 = @floatFromInt(intersections.items.len);
        const keys_len: f64 = @floatFromInt(self.keys.len);
        const depth = std.math.log(f64, keys_len, items_len);
        break :depth @intFromFloat(std.math.ceil(depth));
    };

    if (depth < self.depth) {
        for (depth..self.depth) |_| self.decreaseDepth();
        buffer.clearAndFree();
    } else if (depth > self.depth) {
        for (self.depth..depth) |_| self.increaseDepth();
        buffer.clearAndFree();
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

const Node = struct {
    key: u8,
    children: ?[]Node = null,
    coordinates: ?[2]i32 = null,

    fn checkIfOnScreen(self: *Node) !void {
        if (self.children) |children| {
            for (children) |*child| {
                if (child.children == null and child.coordinates == null) return error.KeyNotFound;
                return child.checkIfOnScreen();
            }
        }
    }

    fn traverseAndFind(self: *Node, buffer: *[][64]u8, index: usize) ![2]i32 {
        if (self.coordinates) |coordinates| return coordinates;
        if (buffer.*.len <= index) {
            try self.checkIfOnScreen();
            return error.EndNotReached;
        }
        if (self.children) |children| {
            for (children) |*child| {
                if (child.key == buffer.*[index][0]) {
                    return child.traverseAndFind(buffer, index + 1);
                }
            }
        }

        return error.KeyNotFound;
    }

    fn traverseAndDraw(self: *Node, path: []u8, index: u8, surface: *const Surface, buffer: [][64]u8, border_mode: bool) void {
        if (self.children) |children| {
            for (children) |*child| {
                path[index] = child.key;

                if (child.coordinates) |coordinates| {
                    var matches: u8 = 0;
                    for (buffer, 0..) |char, i| {
                        if (path[i] == char[0]) matches += 1 else break;
                    }
                    if (buffer.len > matches) matches = 0;

                    const coords = blk: {
                        if (border_mode) {
                            const info = surface.output_info;
                            if (coordinates[0] == info.x and coordinates[1] == info.y) {
                                break :blk .{ coordinates[0] + 5, coordinates[1] + 25 };
                            } else if (coordinates[0] == info.x and coordinates[1] == info.y + info.height - 1) {
                                break :blk .{ coordinates[0] + 5, coordinates[1] - 15 };
                            } else if (coordinates[0] == info.x + info.width - 1 and coordinates[1] == info.y) {
                                break :blk .{ coordinates[0] - 25, coordinates[1] + 25 };
                            } else if (coordinates[0] == info.x + info.width - 1 and coordinates[1] == info.y + info.height - 1) {
                                break :blk .{ coordinates[0] - 25, coordinates[1] - 15 };
                            } else continue;
                        } else {
                            break :blk .{
                                coordinates[0] + surface.config.font.offset[0],
                                coordinates[1] + 20 + surface.config.font.offset[1],
                            };
                        }
                    };

                    surface.renderText(path, coords[0], coords[1], matches);
                } else {
                    child.traverseAndDraw(path, index + 1, surface, buffer, border_mode);
                }
            }
        }
    }

    fn traverseAndPutCoords(self: *Node, intersections: [][2]i32, index: *usize) void {
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

    fn traverseAndCreateChildren(self: *Node, keys: []const u8, alloc: std.mem.Allocator) void {
        if (self.children) |children| {
            for (children) |*child| child.traverseAndCreateChildren(keys, alloc);
        } else {
            self.createChildren(keys, alloc);
        }
    }

    fn traverseAndFreeChildren(self: *Node, alloc: std.mem.Allocator) void {
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

    fn createChildren(self: *Node, keys: []const u8, alloc: std.mem.Allocator) void {
        self.coordinates = null;
        if (self.children == null) {
            const nodes = alloc.alloc(Node, keys.len) catch @panic("OOM");
            for (keys, 0..) |key, i| nodes[i] = Node{ .key = key };
            self.children = nodes;
        }
    }
};
