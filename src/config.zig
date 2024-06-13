const std = @import("std");
const fs = std.fs;

const Lua = @import("ziglua").Lua;
const pango = @import("pango");

fn getPath(alloc: std.mem.Allocator) ![:0]const u8 {
    var args = std.process.args();
    var index: u8 = 0;
    while (args.next()) |arg| : (index += 1) {
        if (index == 0) continue;
        if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
            const path = args.next() orelse {
                std.debug.print("Argument missing after: \"-c\"\nMore info with \"seto -h\"\n", .{});
                std.process.exit(1);
            };

            if (std.mem.eql(u8, path, "null")) return error.Null;

            std.fs.accessAbsolute(path, .{}) catch {
                std.debug.print("File \"{s}\" not found\n", .{path});
                std.process.exit(1);
            };

            return std.fs.path.joinZ(alloc, &[_][]const u8{path});
        }
    }

    const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
    const config_path = fs.path.joinZ(alloc, &[_][]const u8{ home, ".config/seto/config.lua" }) catch @panic("OOM");
    fs.accessAbsolute(config_path, .{}) catch |err| {
        alloc.free(config_path);
        return err;
    };

    return config_path;
}

fn hexToRgba(hex: []const u8) ![4]f64 {
    const start: u8 = if (hex[0] == '#') 1 else 0;

    if (hex.len < 6 + start) {
        return error.InvalidColor;
    }

    const r: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex[0 + start .. 2 + start], 16));
    const g: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex[2 + start .. 4 + start], 16));
    const b: f64 = @floatFromInt(try std.fmt.parseInt(u8, hex[4 + start .. 6 + start], 16));
    const a: f64 = if (hex.len > 6 + start) @floatFromInt(try std.fmt.parseInt(u8, hex[6 + start .. 8 + start], 16)) else 255;

    return .{
        r / 255,
        g / 255,
        b / 255,
        a / 255,
    };
}

pub const Config = struct {
    smooth_scrolling: bool = true,
    output_format: []const u8 = "%x,%y %wx%h\n",
    background_color: [4]f64 = .{ 1, 1, 1, 0.4 },
    keys: Keys,
    font: Font,
    grid: Grid = Grid{},
    alloc: std.mem.Allocator,

    const Self = @This();

    pub fn load(alloc: std.mem.Allocator) Self {
        const config_path = getPath(alloc) catch {
            const keys = Keys{ .search = alloc.dupe(u8, "asdfghjkl") catch @panic("OOM"), .bindings = std.AutoHashMap(u8, Function).init(alloc) };
            const font = Font{
                .family = alloc.dupeZ(u8, "sans-serif") catch @panic("OOM"),
            };
            return Config{
                .alloc = alloc,
                .font = font,
                .keys = keys,
            };
        };
        defer alloc.free(config_path);

        var lua = Lua.init(&alloc) catch @panic("OOM");
        defer lua.deinit();
        lua.doFile(config_path) catch {
            std.debug.print("File {s} couldn't be executed by lua interpreter\n", .{config_path});
            std.process.exit(1);
        };

        var config = Config{ .alloc = alloc, .keys = Keys.new(lua, alloc), .grid = Grid.new(lua), .font = Font.new(lua, alloc) };

        _ = lua.pushString("background_color");
        _ = lua.getTable(1);
        const background_color = lua.toString(2) catch {
            std.debug.print("Background color expected hex value\n", .{});
            std.process.exit(1);
        };
        config.background_color = hexToRgba(background_color) catch {
            std.debug.print("Failed to parse background color\n", .{});
            std.process.exit(1);
        };
        lua.pop(1);

        return config;
    }

    pub fn destroy(self: *Self) void {
        self.alloc.free(self.keys.search);
        self.alloc.free(self.font.family);
        self.keys.bindings.deinit();
    }
};

pub const Font = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    highlight_color: [4]f64 = .{ 1, 1, 0, 1 },
    offset: [2]i32 = .{ 5, 5 },
    size: f64 = 16,
    family: [:0]const u8,
    style: pango.Style = .Normal,
    weight: pango.Weight = .normal,
    variant: pango.Variant = .Normal,
    stretch: pango.Stretch = .Normal,
    gravity: pango.Gravity = .Auto,

    const Self = @This();

    fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
        var font = Font{ .family = alloc.dupeZ(u8, "sans-serif") catch @panic("OOM") };

        _ = lua.pushString("font");
        _ = lua.getTable(1);
        if (lua.isNil(2)) return font;

        _ = lua.pushString("color");
        _ = lua.getTable(2);
        if (!lua.isString(3)) {
            std.debug.print("Font color expected hex value\n", .{});
            std.process.exit(1);
        }
        font.color = hexToRgba(lua.toString(3) catch unreachable) catch {
            std.debug.print("Failed to parse font color\n", .{});
            std.process.exit(1);
        };
        lua.pop(1);

        _ = lua.pushString("highlight_color");
        _ = lua.getTable(2);
        if (!lua.isString(3)) {
            std.debug.print("Font highlight color expected hex value\n", .{});
            std.process.exit(1);
        }
        font.highlight_color = hexToRgba(lua.toString(3) catch unreachable) catch {
            std.debug.print("Failed to parse highlight color\n", .{});
            std.process.exit(1);
        };
        lua.pop(1);

        _ = lua.pushString("size");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            font.size = lua.toNumber(3) catch {
                std.debug.print("Font size should be a number\n", .{});
                std.process.exit(1);
            };
        }
        lua.pop(1);

        _ = lua.pushString("family");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            alloc.free(font.family);
            const font_family = lua.toString(3) catch {
                std.debug.print("Font family should be a string\n", .{});
                std.process.exit(1);
            };
            font.family = alloc.dupeZ(u8, font_family) catch @panic("OOM");
        }
        lua.pop(1);

        font.style = getStyle(pango.Style, "style", lua) catch |err| switch (err) {
            error.OptNotFound => {
                std.debug.print("Font style not found\nSee man 5 seto for more details\n", .{});
                std.process.exit(1);
            },
            else => font.style,
        };

        _ = lua.pushString("weight");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            const result = lua.toNumber(3) catch {
                std.debug.print("Font weight should be a number\n", .{});
                std.process.exit(1);
            };
            font.weight = std.meta.intToEnum(pango.Weight, @as(u32, @intFromFloat(result))) catch |err| @panic(@errorName(err));
        }
        lua.pop(1);

        font.variant = getStyle(pango.Variant, "variant", lua) catch |err| switch (err) {
            error.OptNotFound => {
                std.debug.print("Font variant not found\nSee man 5 seto for more details\n", .{});
                std.process.exit(1);
            },
            else => font.variant,
        };

        font.gravity = getStyle(pango.Gravity, "gravity", lua) catch |err| switch (err) {
            error.OptNotFound => {
                std.debug.print("Font gravity not found\nSee man 5 seto for more details\n", .{});
                std.process.exit(1);
            },
            else => font.gravity,
        };

        font.stretch = getStyle(pango.Stretch, "stretch", lua) catch |err| switch (err) {
            error.OptNotFound => {
                std.debug.print("Font stretch not found\nSee man 5 seto for more details\n", .{});
                std.process.exit(1);
            },
            else => font.stretch,
        };

        _ = lua.pushString("offset");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            lua.pushNil();
            var index: u8 = 0;
            while (lua.next(3)) : (index += 1) {
                if (!lua.isNumber(5) or index > 1) {
                    std.debug.print("Text offset should be in a {{ x, y }} format\n", .{});
                    std.process.exit(1);
                }
                font.offset[index] = @intFromFloat(lua.toNumber(5) catch unreachable);
                lua.pop(1);
            }
            if (index < 2) {
                std.debug.print("Text offset should be in a {{ x, y }} format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        lua.pop(1);
        return font;
    }
};

fn getStyle(comptime T: type, name: [:0]const u8, lua: *Lua) !T {
    _ = lua.pushString(name);
    _ = lua.getTable(2);
    defer lua.pop(1);
    if (!lua.isNil(3)) {
        if (!lua.isString(3)) {
            std.debug.print("Font {s} should be a string\n", .{name});
            std.process.exit(1);
        }
        const result = try lua.toString(3);
        return std.meta.stringToEnum(T, result) orelse return error.OptNotFound;
    }
    return error.NotFound;
}

pub const Grid = struct {
    color: [4]f64 = .{ 1, 1, 1, 1 },
    selected_color: [4]f64 = .{ 1, 0, 0, 1 },
    size: [2]i32 = .{ 80, 80 },
    offset: [2]i32 = .{ 0, 0 },
    line_width: f64 = 2,
    selected_line_width: f64 = 2,

    const Self = @This();

    fn new(lua: *Lua) Self {
        var grid = Grid{};

        _ = lua.pushString("grid");
        _ = lua.getTable(1);

        if (lua.isNil(2)) {
            return grid;
        }

        _ = lua.pushString("color");
        _ = lua.getTable(2);
        const grid_color = lua.toString(3) catch {
            std.debug.print("Grid color expected hex value\n", .{});
            std.process.exit(1);
        };
        grid.color = hexToRgba(grid_color) catch {
            std.debug.print("Failed to parse grid color\n", .{});
            std.process.exit(1);
        };
        lua.pop(1);

        _ = lua.pushString("selected_color");
        _ = lua.getTable(2);
        const grid_selected_color = lua.toString(3) catch {
            std.debug.print("Grid selected color expected hex value\n", .{});
            std.process.exit(1);
        };
        grid.selected_color = hexToRgba(grid_selected_color) catch {
            std.debug.print("Failed to parse selected grid color\n", .{});
            std.process.exit(1);
        };
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
                grid.size[index] = @intFromFloat(lua.toNumber(5) catch unreachable);
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
                grid.offset[index] = @intFromFloat(lua.toNumber(5) catch unreachable);
                lua.pop(1);
            }
            if (index < 2) {
                std.debug.print("Grid offset should be in a {{ x, y }} format\n", .{});
                std.process.exit(1);
            }
        }
        lua.pop(1);

        _ = lua.pushString("line_width");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            grid.line_width = lua.toNumber(3) catch {
                std.debug.print("Line width should be a float\n", .{});
                std.process.exit(1);
            };
        }
        lua.pop(1);

        _ = lua.pushString("selected_line_width");
        _ = lua.getTable(2);
        if (!lua.isNil(3)) {
            grid.selected_line_width = lua.toNumber(3) catch {
                std.debug.print("Selected line width should be a float\n", .{});
                std.process.exit(1);
            };
        }
        lua.pop(1);

        lua.pop(1);
        return grid;
    }

    pub fn move(self: *Self, value: [2]i32) void {
        for (value, 0..) |val, i| {
            if (self.offset[i] < -val) self.offset[i] = self.size[i];
            self.offset[i] += val;
            if (self.offset[i] >= self.size[i]) self.offset[i] -= self.size[i];
        }
    }

    pub fn resize(self: *Self, value: [2]i32) void {
        for (value, 0..) |val, i| {
            var new_size = self.size[i] + val;
            if (new_size <= 0) {
                new_size = 1;
            }
            self.size[i] = new_size;
        }
    }
};

pub const Function = union(enum) {
    border_select,
    resize: [2]i32,
    move: [2]i32,
    move_selection: [2]i32,
    cancel_selection,
    remove,
    quit,

    const Self = @This();

    pub fn stringToFunction(string: []const u8, value: ?[2]i32) !Self {
        if (std.mem.eql(u8, string, "remove")) {
            return .remove;
        } else if (std.mem.eql(u8, string, "quit")) {
            return .quit;
        } else if (std.mem.eql(u8, string, "cancel_selection")) {
            return .cancel_selection;
        } else if (std.mem.eql(u8, string, "move")) {
            return .{ .move = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "resize")) {
            return .{ .resize = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "move_selection")) {
            return .{ .move_selection = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "border_select")) {
            return .border_select;
        }

        return error.UnkownFunction;
    }
};

const Keys = struct {
    search: []const u8,
    bindings: std.AutoHashMap(u8, Function),

    const Self = @This();

    fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
        var keys_s = Keys{ .search = alloc.dupe(u8, "asdfghjkl") catch @panic("OOM"), .bindings = std.AutoHashMap(u8, Function).init(alloc) };

        _ = lua.pushString("keys");
        _ = lua.getTable(1);
        if (lua.isNil(2)) return keys_s;
        _ = lua.pushString("search");
        _ = lua.getTable(2);
        if (lua.isString(3)) {
            alloc.free(keys_s.search);
            const keys = lua.toString(3) catch unreachable;
            keys_s.search = alloc.dupe(u8, keys) catch @panic("OOM");
        }
        lua.pop(1);

        _ = lua.pushString("bindings");
        _ = lua.getTable(2);

        if (!lua.isNil(3)) {
            lua.pushNil();
            while (lua.next(3)) {
                const key: u8 = if (lua.isNumber(4))
                    @intFromFloat(lua.toNumber(4) catch unreachable)
                else
                    (lua.toString(4) catch unreachable)[0];

                const value: std.meta.Tuple(&.{ [*:0]const u8, ?[2]i32 }) = x: {
                    if (lua.isString(5)) {
                        break :x .{ lua.toString(5) catch unreachable, null };
                    } else {
                        defer lua.pop(3);
                        const inner_key: [2]u8 = .{ key, 0 };
                        _ = lua.pushString(inner_key[0..1 :0]);
                        _ = lua.getTable(5);
                        _ = lua.pushNil();
                        if (lua.next(5)) {
                            var move_value: [2]i32 = undefined;
                            var index: u8 = 0;
                            _ = lua.pushNil();
                            const function = lua.toString(7) catch unreachable;
                            while (lua.next(8)) : (index += 1) {
                                move_value[index] = @intFromFloat(lua.toNumber(10) catch {
                                    std.debug.print("{s} expected number\n", .{function});
                                    std.process.exit(1);
                                });
                                lua.pop(1);
                            }
                            break :x .{ function, move_value };
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
                keys_s.bindings.put(key, func) catch @panic("OOM");
                lua.pop(1);
            }
        }
        lua.pop(2);
        return keys_s;
    }
};

const assert = std.debug.assert;

test "resize" {
    for (1..10) |i| {
        var grid = Grid{};
        var initial = grid.size;
        const index: i32 = @intCast(i);
        grid.resize(.{ index, 0 });
        assert(grid.size[0] == initial[0] + index);

        grid.resize(.{ 0, index });
        assert(grid.size[1] == initial[1] + index);

        initial = grid.size;
        grid.resize(.{ -index, 0 });
        assert(grid.size[0] == initial[0] - index);

        grid.resize(.{ 0, -index });
        assert(grid.size[1] == initial[1] - index);

        grid.size[0] = index;
        grid.size[1] = index;
        initial = grid.size;
        grid.resize(.{ -std.math.maxInt(i32), 0 });
        assert(grid.size[0] == 1);

        grid.resize(.{ 0, -std.math.maxInt(i32) });
        assert(grid.size[1] == 1);
    }
}

test "move" {
    for (1..10) |i| {
        var grid = Grid{};
        var initial = grid.offset;
        const index: i32 = @intCast(i);
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

test "hex_to_rgba" {
    var rgba = try hexToRgba("#FFFFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }

    rgba = try hexToRgba("FFFFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }

    rgba = try hexToRgba("FFFFFF");
    for (rgba) |color| {
        assert(color == 1);
    }
}
