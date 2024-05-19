const std = @import("std");
const cairo = @import("cairo");
const ziglua = @import("ziglua");
const Lua = ziglua.Lua;
const fs = std.fs;
const assert = std.debug.assert;

pub const Config = struct {
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    keys: Keys,
    font: Font = Font{},
    grid: Grid = Grid{},

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator) !Self {
        var a_alloc = std.heap.ArenaAllocator.init(allocator);
        const alloc = a_alloc.allocator();
        defer a_alloc.deinit();

        const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
        const config_dir = try fs.path.join(alloc, &[_][]const u8{ home, ".config/seto" });
        fs.accessAbsolute(config_dir, .{}) catch {
            _ = try fs.makeDirAbsolute(config_dir);
        };
        const config_path = try fs.path.join(alloc, &[_][]const u8{ config_dir, "config.lua" });
        fs.accessAbsolute(config_path, .{}) catch {
            const file = try fs.createFileAbsolute(config_path, .{});
            std.debug.print("Config file not found, creating one at {s}\n", .{config_path});
            _ = try file.write(config);
        };

        var buf: [4098]u8 = undefined;
        const file = try fs.openFileAbsolute(config_path, .{});
        const read_bytes = try file.read(&buf);
        buf[read_bytes] = 0;

        var keys = Keys{ .bindings = std.AutoHashMap(u8, Function).init(allocator) };

        var lua = try Lua.init(alloc);
        try lua.doString(buf[0..read_bytes :0]);
        _ = try lua.getGlobal("config");
        _ = lua.pushString("keys");
        _ = lua.getTable(-2);
        _ = lua.pushString("search");
        _ = lua.getTable(-2);
        const a = try lua.toString(-1);
        const len = std.mem.len(a);

        const temp = try allocator.alloc(u8, len);
        @memcpy(temp, a[0..len]);
        keys.search = temp;

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

        if (keys.search.len <= 1) {
            std.debug.print("Error: A minimum of two search keys required.\n", .{});
            std.process.exit(1);
        }

        return .{ .keys = keys };
    }
};

const config =
    \\Config = {
    \\    background_color = {1, 1, 1, 0.4},
    \\    font = {
    \\        color = {1, 1, 1},
    \\        highlight_color = {1, 1, 0},
    \\        size = 16,
    \\        family = "JetBrainsMono Nerd Font",
    \\        slant = "Normal",
    \\        weight = "Normal",
    \\    },
    \\    grid = {
    \\        color = {1, 1, 1, 1},
    \\        size = {80, 80},
    \\        offset = {0, 0},
    \\    },
    \\    keys = {
    \\        search = "asdfghjkl",
    \\        bindings = {
    \\            z = {moveX = -5},
    \\            x = {moveY = 5},
    \\            n = {moveY = -5},
    \\            m = {moveX = 5},
    \\            Z = {resizeX = -5},
    \\            X = {resizeY = 5},
    \\            N = {resizeY = -5},
    \\            M = {resizeX = 5},
    \\            [8] = "remove",
    \\            q = "quit",
    \\        },
    \\    },
    \\}
;

pub const Font = struct {
    color: [3]f64 = .{ 1, 1, 1 },
    highlight_color: [3]f64 = .{ 1, 1, 0 },
    size: f64 = 16,
    family: [:0]const u8 = "JetBransMono Nerd Font",
    slant: cairo.FontFace.FontSlant = .Normal,
    weight: cairo.FontFace.FontWeight = .Normal,
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
        var new_size = self.size[0] + value;
        if (new_size <= 0) {
            new_size = 1;
        }
        self.size[0] = new_size;
    }

    pub fn resizeY(self: *Self, value: i32) void {
        var new_size = self.size[1] + value;
        if (new_size <= 0) {
            new_size = 1;
        }
        self.size[1] = new_size;
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

test "resize" {
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
        grid.resizeX(-std.math.maxInt(i32));
        assert(grid.size[0] == 1);

        grid.resizeY(-std.math.maxInt(i32));
        assert(grid.size[1] == 1);
    }
}

test "move" {
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
