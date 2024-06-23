//var ft: c.FT_Library = undefined;
//if (c.FT_Init_FreeType(&ft) == 1) {
//    std.log.err("Could not init FreeType Library\n", .{});
//}

//var face: c.FT_Face = undefined;
//if (c.FT_New_Face(ft, "/nix/store/09w34ps5vacfih6qn6rh3dkc29ax86fr-dejavu-fonts-minimal-2.37/share/fonts/truetype/DejaVuSans.ttf", 0, &face) == 1) {
//    std.log.err("Failed to load font\n", .{});
//}

//_ = c.FT_Set_Pixel_Sizes(face, 0, 48);

//if (c.FT_Load_Char(face, 'X', c.FT_LOAD_RENDER) == 1) {
//    std.log.err("Failed to load character\n", .{});
//}

//const char_map = std.ArrayList(Character).init(alloc);
//_ = char_map;

const Lua = @import("ziglua").Lua;
const std = @import("std");
const hexToRgba = @import("../helpers.zig").hexToRgba;

color: [4]f32 = .{ 1, 1, 1, 1 },
highlight_color: [4]f32 = .{ 1, 1, 0, 1 },
offset: [2]i32 = .{ 5, 5 },
size: f64 = 16,
family: [:0]const u8,

const Self = @This();

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var font = Self{ .family = alloc.dupeZ(u8, "sans-serif") catch @panic("OOM") };

    _ = lua.pushString("font");
    _ = lua.getTable(1);
    if (lua.isNil(2)) return font;

    _ = lua.pushString("color");
    _ = lua.getTable(2);
    if (!lua.isString(3)) {
        std.log.err("Font color expected hex value\n", .{});
        std.process.exit(1);
    }
    font.color = hexToRgba(lua.toString(3) catch unreachable) catch {
        std.log.err("Failed to parse font color\n", .{});
        std.process.exit(1);
    };
    lua.pop(1);

    _ = lua.pushString("highlight_color");
    _ = lua.getTable(2);
    if (!lua.isString(3)) {
        std.log.err("Font highlight color expected hex value\n", .{});
        std.process.exit(1);
    }
    font.highlight_color = hexToRgba(lua.toString(3) catch unreachable) catch {
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
