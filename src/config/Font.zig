const std = @import("std");
const helpers = @import("../helpers.zig");

const hexToRgba = helpers.hexToRgba;

const Lua = @import("ziglua").Lua;
const Color = helpers.Color;

color: Color,
highlight_color: Color,
offset: [2]i32 = .{ 5, 5 },
size: f64 = 16,
family: [:0]const u8,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    return .{
        .color = Color.parse("#FFFFFF", alloc) catch unreachable,
        .highlight_color = Color.parse("#FFFF00", alloc) catch unreachable,
        .family = alloc.dupeZ(u8, "sans-serif") catch @panic("OOM"),
    };
}

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var font = Self.default(alloc);

    _ = lua.pushString("font");
    _ = lua.getTable(1);
    if (lua.isNil(2)) return font;

    _ = lua.pushString("color");
    _ = lua.getTable(2);
    const font_color = lua.toString(3) catch {
        std.log.err("Font color expected hex value\n", .{});
        std.process.exit(1);
    };
    font.color = Color.parse(font_color, alloc) catch {
        std.log.err("Failed to parse font color\n", .{});
        std.process.exit(1);
    };
    lua.pop(1);

    _ = lua.pushString("highlight_color");
    _ = lua.getTable(2);
    const font_highlight_color = lua.toString(3) catch {
        std.log.err("Font highlight color expected hex value\n", .{});
        std.process.exit(1);
    };
    font.highlight_color = Color.parse(font_highlight_color, alloc) catch {
        std.log.err("Failed to parse highlight color\n", .{});
        std.process.exit(1);
    };
    lua.pop(1);

    _ = lua.pushString("size");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        font.size = lua.toNumber(3) catch {
            std.log.err("Font size should be a number\n", .{});
            std.process.exit(1);
        };
    }
    lua.pop(1);

    _ = lua.pushString("family");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        alloc.free(font.family);
        const font_family = lua.toString(3) catch {
            std.log.err("Font family should be a string\n", .{});
            std.process.exit(1);
        };
        font.family = alloc.dupeZ(u8, font_family) catch @panic("OOM");
    }
    lua.pop(1);

    _ = lua.pushString("offset");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        lua.pushNil();
        var index: u8 = 0;
        while (lua.next(3)) : (index += 1) {
            if (!lua.isNumber(5) or index > 1) {
                std.log.err("Text offset should be in a {{ x, y }} format\n", .{});
                std.process.exit(1);
            }
            font.offset[index] = @intFromFloat(lua.toNumber(5) catch unreachable);
            lua.pop(1);
        }
        if (index < 2) {
            std.log.err("Text offset should be in a {{ x, y }} format\n", .{});
            std.process.exit(1);
        }
    }
    lua.pop(1);

    lua.pop(1);

    return font;
}
