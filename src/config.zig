const std = @import("std");
const yaml = @import("yaml");
const fs = std.fs;

pub const Config = struct {
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    keys: Keys,
    font: Font = Font{},
    grid: Grid = Grid{},

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator) !Self {
        // TODO: Leaving it commented until I find some config lang parser
        //  var a_alloc = std.heap.ArenaAllocator.init(allocator);
        //  const alloc = a_alloc.allocator();
        //  defer a_alloc.deinit();

        //  const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
        //  const config_dir = try fs.path.join(alloc, &[_][]const u8{ home, ".config/seto" });
        //  fs.accessAbsolute(config_dir, .{}) catch {
        //      _ = try fs.makeDirAbsolute(config_dir);
        //  };
        //  const config_file = try fs.path.join(alloc, &[_][]const u8{ config_dir, "config.yaml" });
        //  fs.accessAbsolute(config_file, .{}) catch {
        //      const file = try fs.createFileAbsolute(config_file, .{});
        //      std.debug.print("Config file not found, creating one at {s}\n", .{config_file});
        //      _ = try file.write(config);
        //  };

        var keys = Keys{ .bindings = std.AutoHashMap(u8, Function).init(allocator) };
        try keys.bindings.put('z', .{ .moveX = -5 });
        try keys.bindings.put('x', .{ .moveY = 5 });
        try keys.bindings.put('n', .{ .moveY = -5 });
        try keys.bindings.put('m', .{ .moveX = 5 });

        try keys.bindings.put('Z', .{ .resizeX = -5 });
        try keys.bindings.put('X', .{ .resizeY = 5 });
        try keys.bindings.put('N', .{ .resizeY = -5 });
        try keys.bindings.put('M', .{ .resizeX = 5 });

        try keys.bindings.put(8, .remove);

        try keys.bindings.put('q', .quit);

        return .{ .keys = keys };
    }
};

const Font = struct {
    color: [3]f64 = .{ 1, 1, 1 },
    highlight_color: [3]f64 = .{ 1, 1, 0 },
    size: f64 = 16,
    family: [:0]const u8 = "Arial",
};

pub const Grid = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    size: [2]isize = .{ 80, 80 },
    offset: [2]isize = .{ 0, 0 },

    const Self = @This();

    pub fn moveX(self: *Self, value: i32) void {
        if (self.offset[0] < -value) self.offset[0] = self.size[0];
        self.offset[0] += value;
        if (self.offset[0] >= self.size[0]) self.offset[0] -= self.size[0];
    }

    pub fn moveY(self: *Self, value: i32) void {
        if (self.offset[1] < -value) self.offset[1] = self.size[1];
        self.offset[1] += value;
        if (self.offset[1] >= self.size[1]) self.offset[1] -= self.size[1];
    }

    pub fn resizeX(self: *Self, value: i32) void {
        if (self.size[0] + value >= 0) self.size[0] += value else {
            self.size[0] += value;
            self.size[0] = -self.size[0];
        }
    }

    pub fn resizeY(self: *Self, value: i32) void {
        if (self.size[1] + value >= 0) self.size[1] += value else {
            self.size[0] += value;
        }
    }
};

const Function = union(enum) {
    resizeX: i32,
    resizeY: i32,
    moveX: i32,
    moveY: i32,
    remove,
    quit,
};

const Keys = struct {
    search: []const u8 = "asdfghjkl",
    bindings: std.AutoHashMap(u8, Function),
};

const config = "background_color: [ 1, 1, 1, 0.4 ]\nkeys:\n    search: asdfghjkl\n    move: [ z, x, n, m ]\n    resize: [ Z, X, N, M ]\nfont:\n    color: [ 1, 1, 1 ]\n    highlight_color: [ 1, 1, 0 ]\n    size: 16\n    family: Arial\ngrid:\n    color: [ 1, 1, 1, 1]\n    size: [ 80, 80 ]\n    offset:    [ 0, 0 ]";

test "resize" {
    const assert = std.debug.assert;

    for (1..10) |i| {
        var grid = Grid{};
        var initial = grid.size;
        const index: i32 = @intCast(i);
        grid.resizeX(index);
        assert(grid.size[0] == initial[0] + index);

        grid.resizeY(index);
        assert(grid.size[1] == initial[1] + index);

        initial = grid.size;
        grid.resizeX(-index);
        assert(grid.size[0] == initial[0] - index);

        grid.resizeY(-index);
        assert(grid.size[1] == initial[1] - index);

        grid.size[0] = index;
        grid.size[1] = index;
        initial = grid.size;
        grid.resizeX(-index * 2);
        assert(grid.size[0] == index);

        grid.resizeY(-index * 2);
        assert(grid.size[1] == index);

        grid.resizeX(index * 2);
        assert(grid.size[0] == index);

        grid.resizeY(index);
        assert(grid.size[1] == initial[1] + index);
    }
}

test "move" {
    const assert = std.debug.assert;

    for (1..10) |i| {
        var grid = Grid{};
        var initial = grid.offset;
        const index: i32 = @intCast(i);
        grid.moveX(index);
        assert(grid.offset[0] == initial[0] + index);

        grid.moveY(index);
        assert(grid.offset[1] == initial[1] + index);

        grid.offset[0] = 0;
        initial = grid.offset;
        grid.moveX(-index);
        assert(grid.offset[0] == grid.size[0] - index);

        grid.offset[1] = 0;
        initial = grid.offset;
        grid.moveY(-index);
        assert(grid.offset[1] == grid.size[1] - index);

        initial = grid.offset;
        grid.moveX(index * 2);
        assert(grid.offset[0] == index);

        grid.moveY(index * 2);
        assert(grid.offset[1] == index);
    }
}
