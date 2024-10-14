const std = @import("std");
const helpers = @import("helpers");

const hexToRgba = helpers.hexToRgba;

const Lua = @import("ziglua").Lua;
const Color = helpers.Color;
const Font = @import("Font.zig");

min_size: [2]f32 = .{ 1, 1 },
color: Color,
selected_color: Color,
size: [2]f32 = .{ 80, 80 },
offset: [2]f32 = .{ 0, 0 },
line_width: f32 = 2,
selected_line_width: f32 = 2,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    return .{
        .selected_color = Color.parse("FF0000", alloc) catch unreachable,
        .color = Color.parse("FFFFFF", alloc) catch unreachable,
    };
}

pub fn init(lua: *Lua, alloc: std.mem.Allocator) Self {
    var grid = Self.default(alloc);

    _ = lua.pushString("grid");
    _ = lua.getTable(1);

    if (lua.isNil(2)) {
        return grid;
    }

    _ = lua.pushString("color");
    _ = lua.getTable(2);
    const grid_color = lua.toString(3) catch @panic("grid.color expected string");
    lua.pop(1);

    grid.color = Color.parse(grid_color, alloc) catch @panic("Failed to parse grid.color");

    _ = lua.pushString("selected_color");
    _ = lua.getTable(2);
    const grid_selected_color = lua.toString(3) catch @panic("grid.selected_color expected string");
    grid.selected_color = Color.parse(grid_selected_color, alloc) catch @panic("Failed to parse grid.selected_color");
    lua.pop(1);

    _ = lua.pushString("size");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        lua.pushNil();
        var index: u8 = 0;
        while (lua.next(3)) : (index += 1) {
            if (index > 1) @panic("Grid size should be in a {{ width, height }} format\n");
            grid.size[index] = @floatCast(lua.toNumber(5) catch @panic("grid.size expected list of numbers"));
            lua.pop(1);
        }
        if (index < 2) @panic("Grid size should be in a {{ width, height }} format\n");
    }
    lua.pop(1);

    _ = lua.pushString("line_width");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        grid.line_width = @floatCast(lua.toNumber(3) catch {
            std.log.err("Line width should be a float\n", .{});
            std.process.exit(1);
        });
    }
    lua.pop(1);

    _ = lua.pushString("selected_line_width");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        grid.selected_line_width = @floatCast(lua.toNumber(3) catch @panic("grid.selected_line_width expected number"));
    }
    lua.pop(2);
    return grid;
}

pub fn move(self: *Self, value: [2]f32) void {
    for (value, 0..) |val, i| {
        var new_offset = self.offset[i] + val;

        new_offset = @rem(new_offset + self.size[i], self.size[i]);

        self.offset[i] = new_offset;
    }
}

pub fn resize(self: *Self, value: [2]f32) void {
    for (value, 0..) |val, i| {
        const new_size = self.size[i] + val;

        self.offset[i] = @rem(self.offset[i], self.size[i]);

        self.size[i] = new_size;
    }
}

test "resize" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    for (1..10) |i| {
        var grid = Self.default(alloc);
        var initial = grid.size;
        const index: f32 = @floatFromInt(i);
        grid.resize(.{ index, 0 });
        assert(grid.size[0] == initial[0] + index);

        grid.resize(.{ 0, index });
        assert(grid.size[1] == initial[1] + index);

        initial = grid.size;
        grid.resize(.{ -index, 0 });
        assert(grid.size[0] == initial[0] - index);

        grid.resize(.{ 0, -index });
        assert(grid.size[1] == initial[1] - index);
    }
}

test "move" {
    const assert = std.debug.assert;
    const alloc = std.heap.page_allocator;

    for (1..10) |i| {
        var grid = Self.default(alloc);
        var initial = grid.offset;
        const index: f32 = @floatFromInt(i);
        grid.move(.{ index, 0 });
        assert(grid.offset[0] == initial[0] + index);

        grid.move(.{ 0, index });
        assert(grid.offset[1] == initial[1] + index);

        grid.offset[0] = 0;
        initial = grid.offset;
        grid.move(.{ -index, 0 });
        assert(grid.offset[0] == grid.size[0] - index);

        grid.offset[1] = 0;
        initial = grid.offset;
        grid.move(.{ 0, -index });
        assert(grid.offset[1] == grid.size[1] - index);

        initial = grid.offset;
        grid.move(.{ index * 2, 0 });
        assert(grid.offset[0] == index);

        grid.move(.{ 0, index * 2 });
        assert(grid.offset[1] == index);
    }
}
