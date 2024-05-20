const std = @import("std");
const cairo = @import("cairo");
const ziglua = @import("ziglua");
const Lua = ziglua.Lua;
const fs = std.fs;
const assert = std.debug.assert;

fn getPath(alloc: std.mem.Allocator) ![:0]u8 {
    const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
    const config_dir = try fs.path.join(alloc, &[_][]const u8{ home, ".config/seto" });
    fs.accessAbsolute(config_dir, .{}) catch {
        _ = try fs.makeDirAbsolute(config_dir);
    };
    const config_path = try fs.path.joinZ(alloc, &[_][]const u8{ config_dir, "config.lua" });
    fs.accessAbsolute(config_path, .{}) catch {
        const file = try fs.createFileAbsolute(config_path, .{});
        std.debug.print("Config file not found, creating one at {s}\n", .{config_path});
        _ = try file.write(lua_config);
    };

    return config_path;
}

pub const Config = struct {
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    keys: Keys,
    font: Font,
    grid: Grid,
    alloc: std.mem.Allocator,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator) !Self {
        var a_alloc = std.heap.ArenaAllocator.init(allocator);
        defer a_alloc.deinit();

        const config_path = try getPath(a_alloc.allocator());

        var lua = try Lua.init(a_alloc.allocator());
        try lua.doFile(config_path);

        var config = Config{ .alloc = allocator, .keys = try Keys.new(&lua, &a_alloc), .grid = try Grid.new(&lua), .font = try Font.new(&lua, a_alloc.child_allocator) };

        _ = lua.pushString("background_color");
        _ = lua.getTable(1);
        if (!lua.isNil(2)) {
            var index: u8 = 0;
            lua.pushNil();
            while (lua.next(2)) : (index += 1) {
                if (!lua.isNumber(4) or index > 3) {
                    std.debug.print("Background color should be in RGBA format\n", .{});
                    std.process.exit(1);
                }
                config.background_color[index] = try lua.toNumber(4);
                lua.pop(1);
            }
            if (index < 4) {
                std.debug.print("Background color should be in RGBA format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        return config;
    }

    pub fn destroy(self: *Self) void {
        self.alloc.free(self.keys.search);
        self.alloc.free(self.font.family);
    }
};

pub const Font = struct {
    color: [3]f64 = .{ 1, 1, 1 },
    highlight_color: [3]f64 = .{ 1, 1, 0 },
    size: f64 = 16,
    family: [:0]const u8,
    slant: cairo.FontFace.FontSlant = .Normal,
    weight: cairo.FontFace.FontWeight = .Normal,

    const Self = @This();

    fn new(lua: *Lua, alloc: std.mem.Allocator) !Self {
        var buf = try alloc.alloc(u8, 6);
        @memcpy(buf[0..5], "Arial");
        buf[5] = 0;
        var font = Font{ .family = buf[0..5 :0] };

        _ = lua.pushString("font");
        _ = lua.getTable(1);
        if (lua.isNil(2)) return font;

        _ = lua.pushString("color");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 2) {
                    std.debug.print("Font color should be in a RGB format\n", .{});
                    std.process.exit(1);
                }
                font.color[index] = try lua.toNumber(5);
                lua.pop(1);
            }
            if (index < 3) {
                std.debug.print("Font color should be in a RGB format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        _ = lua.pushString("highlight_color");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 2) {
                    std.debug.print("Font highlight color should be in a RGB format\n", .{});
                    std.process.exit(1);
                }
                font.highlight_color[index] = try lua.toNumber(5);
                lua.pop(1);
            }
            if (index < 3) {
                std.debug.print("Font highlight color should be in a RGB format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        _ = lua.pushString("size");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            if (!lua.isNumber(3)) {
                std.debug.print("Font size should be a number\n", .{});
                std.process.exit(1);
            }
            font.size = try lua.toNumber(3);
        }
        lua.pop(1);

        _ = lua.pushString("family");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            alloc.free(font.family);
            if (!lua.isString(3)) {
                std.debug.print("Font family should be a string\n", .{});
                std.process.exit(1);
            }
            const font_family = try lua.toString(3);
            const len = std.mem.len(font_family);
            const buffer = try alloc.alloc(u8, len + 1);
            buffer[len] = 0;
            @memcpy(buffer[0..len], font_family[0..len]);
            font.family = buffer[0..len :0];
        }
        lua.pop(1);

        _ = lua.pushString("slant");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            if (!lua.isString(3)) {
                std.debug.print("Font slant should be a string\n", .{});
                std.process.exit(1);
            }
            const font_slant = try lua.toString(3);
            font.slant = std.meta.stringToEnum(cairo.FontFace.FontSlant, std.mem.span(font_slant)) orelse {
                std.debug.print("Font slant \"{s}\" not found\nAvailable options are:\n - Normal\n - Italic \n - Oblique\n", .{font_slant});
                std.process.exit(1);
            };
        }
        lua.pop(1);

        _ = lua.pushString("weight");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            if (!lua.isString(3)) {
                std.debug.print("Font weight should be a string\n", .{});
                std.process.exit(1);
            }
            const font_weight = try lua.toString(3);
            font.weight = std.meta.stringToEnum(cairo.FontFace.FontWeight, std.mem.span(font_weight)) orelse {
                std.debug.print("Font weight \"{s}\" not found\nAvailable options are:\n - Normal\n - Bold\n", .{font_weight});
                std.process.exit(1);
            };
        }
        lua.pop(1);

        lua.pop(1);
        return font;
    }
};

pub const Grid = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    size: [2]isize = .{ 80, 80 },
    offset: [2]isize = .{ 0, 0 },

    const Self = @This();

    fn new(lua: *Lua) !Self {
        var grid = Grid{};

        _ = lua.pushString("grid");
        _ = lua.getTable(1);

        if (lua.isNil(2)) {
            return grid;
        }

        _ = lua.pushString("color");
        _ = lua.getTable(2);

        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 3) {
                    std.debug.print("Grid color should be in a RGBA format\n", .{});
                    std.process.exit(1);
                }
                grid.color[index] = try lua.toNumber(5);
                lua.pop(1);
            }
            if (index < 4) {
                std.debug.print("Grid color should be in a RGBA format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        _ = lua.pushString("size");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 1) {
                    std.debug.print("Grid size should be in a {{ width, height }} format\n", .{});
                    std.process.exit(1);
                }
                grid.size[index] = @intFromFloat(try lua.toNumber(5));
                lua.pop(1);
            }
            if (index < 2) {
                std.debug.print("Grid size should be in a {{ width, height }} format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        _ = lua.pushString("offset");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 1) {
                    std.debug.print("Grid offset should be in a {{ x, y }} format\n", .{});
                    std.process.exit(1);
                }
                grid.offset[index] = @intFromFloat(try lua.toNumber(5));
                lua.pop(1);
            }
            if (index < 2) {
                std.debug.print("Grid offset should be in a {{ x, y }} format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        lua.pop(1);
        return grid;
    }

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

    const Self = @This();

    fn stringToFunction(string: []const u8, value: ?i32) !Self {
        if (std.mem.eql(u8, string, "remove")) {
            return .remove;
        } else if (std.mem.eql(u8, string, "quit")) {
            return .quit;
        } else if (std.mem.eql(u8, string, "moveX")) {
            return .{ .moveX = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "moveY")) {
            return .{ .moveY = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "resizeX")) {
            return .{ .resizeX = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "resizeY")) {
            return .{ .resizeY = value orelse return error.NullValue };
        }

        return error.UnkownFunction;
    }
};

const Keys = struct {
    search: []const u8,
    bindings: std.AutoHashMap(u8, Function),

    const Self = @This();

    fn new(lua: *Lua, alloc: *std.heap.ArenaAllocator) !Self {
        const default_search = try alloc.child_allocator.alloc(u8, 9);
        @memcpy(default_search, "asdfghjkl");

        var keys_s = Keys{ .search = default_search, .bindings = std.AutoHashMap(u8, Function).init(alloc.child_allocator) };

        _ = lua.pushString("keys");
        _ = lua.getTable(1);
        if (lua.isNil(2)) return keys_s;
        _ = lua.pushString("search");
        _ = lua.getTable(2);
        if (lua.isString(3)) {
            alloc.child_allocator.free(default_search);
            const keys = try lua.toString(3);

            keys_s.search = create_buffer: {
                const len = std.mem.len(keys);
                if (len <= 1) {
                    std.debug.print("Error: A minimum of two search keys required.\n", .{});
                    std.process.exit(1);
                }

                const buffer = try alloc.child_allocator.alloc(u8, len);
                @memcpy(buffer, keys[0..len]);
                break :create_buffer buffer;
            };
        }
        lua.pop(1);

        _ = lua.pushString("bindings");
        _ = lua.getTable(2);

        if (!lua.isNil(3)) {
            lua.pushNil();
            while (lua.next(3)) {
                const key: u8 = if (lua.isNumber(4))
                    @intFromFloat(try lua.toNumber(4))
                else
                    (try lua.toString(4))[0];

                const value: std.meta.Tuple(&.{ [*:0]const u8, ?i32 }) = x: {
                    if (lua.isString(5)) {
                        break :x .{ try lua.toString(5), null };
                    } else {
                        defer lua.pop(3);
                        const inner_key: [2]u8 = .{ key, 0 };
                        _ = lua.pushString(inner_key[0..1 :0]);
                        _ = lua.getTable(5);
                        _ = lua.pushNil();
                        if (lua.next(5)) {
                            break :x .{ try lua.toString(7), @intFromFloat(try lua.toNumber(8)) };
                        }
                    }
                };

                const len = std.mem.len(value.@"0");
                const func = Function.stringToFunction(value.@"0"[0..len], value.@"1") catch |err| {
                    switch (err) {
                        error.UnkownFunction => std.debug.print("Unkown function \"{s}\"\n", .{value.@"0"[0..len]}),
                        error.NullValue => std.debug.print("Value for function \"{s}\" can't be null\n", .{value.@"0"[0..len]}),
                    }
                    std.process.exit(1);
                };
                try keys_s.bindings.put(key, func);
                lua.pop(1);
            }
        }
        lua.pop(2);
        return keys_s;
    }
};

const lua_config =
    \\return {
    \\	background_color = { 1, 1, 1, 0.4 },
    \\	font = {
    \\		color = { 1, 1, 1 },
    \\		highlight_color = { 1, 1, 0 },
    \\		size = 16,
    \\		family = "Arial",
    \\		slant = "Normal",
    \\		weight = "Normal",
    \\	},
    \\	grid = {
    \\		color = { 1, 1, 1, 1 },
    \\		size = { 80, 80 },
    \\		offset = { 0, 0 },
    \\	},
    \\	keys = {
    \\		search = "asdfghjkl",
    \\		bindings = {
    \\			z = { moveX = -5 },
    \\			x = { moveY = 5 },
    \\			n = { moveY = -5 },
    \\			m = { moveX = 5 },
    \\			Z = { resizeX = -5 },
    \\			X = { resizeY = 5 },
    \\			N = { resizeY = -5 },
    \\			M = { resizeX = 5 },
    \\			[8] = "remove",
    \\			q = "quit",
    \\		},
    \\	},
    \\}
;

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
