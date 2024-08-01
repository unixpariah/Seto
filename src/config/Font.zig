const std = @import("std");
const helpers = @import("helpers");

const hexToRgba = helpers.hexToRgba;

const Lua = @import("ziglua").Lua;
const Color = helpers.Color;

weight: ?f32 = null,
color: Color,
highlight_color: Color,
offset: [2]i32 = .{ 5, 5 },
size: f32 = 20,
family: [:0]const u8,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    return .{ // These are hardcoded so no way for error
        .color = Color.parse("#FFFFFF", alloc) catch unreachable,
        .highlight_color = Color.parse("#FFFF00", alloc) catch unreachable,
        .family = alloc.dupeZ(u8, "monospace") catch @panic("OOM"),
    };
}

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var font = Self.default(alloc);

    _ = lua.pushString("font");
    _ = lua.getTable(1);
    if (lua.isNil(2)) return font;

    _ = lua.pushString("color");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        const font_color = lua.toString(3) catch @panic("font.color expected string");
        font.color = Color.parse(font_color, alloc) catch @panic("Failed to parse font.color");
    }
    lua.pop(1);

    _ = lua.pushString("highlight_color");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        const font_highlight_color = lua.toString(3) catch @panic("font.hightlight_color expected string");
        font.highlight_color = Color.parse(font_highlight_color, alloc) catch @panic("Failed to parse font.highlight_color");
    }
    lua.pop(1);

    _ = lua.pushString("size");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        font.size = @floatCast(lua.toNumber(3) catch @panic("font.size expected number"));
    }
    lua.pop(1);

    _ = lua.pushString("weight");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        font.weight = @floatCast(lua.toNumber(3) catch @panic("font.weight expected number"));
    }
    lua.pop(1);

    _ = lua.pushString("family");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        alloc.free(font.family);
        const font_family = lua.toString(3) catch @panic("font.family expected string");
        font.family = alloc.dupeZ(u8, font_family) catch @panic("OOM");
    }
    lua.pop(1);

    _ = lua.pushString("offset");
    _ = lua.getTable(2);
    if (!lua.isNil(3)) {
        lua.pushNil();
        var index: u8 = 0;
        while (lua.next(3)) : (index += 1) {
            if (index > 1) @panic("font.offset expected {{ x, y }} format");
            const coordinate = lua.toNumber(5) catch @panic("font.offset expected list of numbers");
            font.offset[index] = @intFromFloat(coordinate);
            lua.pop(1);
        }
        if (index < 2) @panic("font.offset expected {{ x, y }} format");
    }
    lua.pop(2);

    return font;
}
