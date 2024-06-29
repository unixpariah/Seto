const std = @import("std");
const c = @import("../ffi.zig");

const Lua = @import("ziglua").Lua;

pub const Character = struct {
    texture_id: u32,
    size: [2]f32,
    bearing: [2]f32,
    advance: [2]f32,

    fn new(face: c.FT_Face, key: u8) Character {
        if (c.FT_Load_Char(face, key, c.FT_LOAD_RENDER) == 1) {
            std.log.err("Failed to load glyph {s}\n", .{[_]u8{key}});
            std.process.exit(1);
        }

        var texture: u32 = undefined;
        c.glGenTextures(1, &texture);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);
        c.glTexImage2D(
            c.GL_TEXTURE_2D,
            0,
            c.GL_RED,
            @intCast(face.*.glyph.*.bitmap.width),
            @intCast(face.*.glyph.*.bitmap.rows),
            0,
            c.GL_RED,
            c.GL_UNSIGNED_BYTE,
            face.*.glyph.*.bitmap.buffer,
        );

        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

        return .{
            .texture_id = texture,
            .size = .{
                @floatFromInt(face.*.glyph.*.bitmap.width),
                @floatFromInt(face.*.glyph.*.bitmap.rows),
            },
            .bearing = .{
                @floatFromInt(face.*.glyph.*.bitmap_top),
                @floatFromInt(face.*.glyph.*.bitmap_left),
            },
            .advance = .{
                @floatFromInt(face.*.glyph.*.advance.x),
                @floatFromInt(face.*.glyph.*.advance.y),
            },
        };
    }
};

search: []const u8,
bindings: std.AutoHashMap(u8, Function),
char_info: std.AutoHashMap(u8, Character),

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    return .{
        .search = alloc.dupe(u8, "asdfghjkl") catch @panic("OOM"),
        .bindings = std.AutoHashMap(u8, Function).init(alloc),
        .char_info = std.AutoHashMap(u8, Character).init(alloc),
    };
}

pub fn new(lua: *Lua, alloc: std.mem.Allocator, font_name: []const u8) Self {
    var keys_s = Self.default(alloc);

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
                                std.log.err("{s} expected number\n", .{function});
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
                    error.UnkownFunction => std.log.err("Unkown function \"{s}\"\n", .{value.@"0"[0..len]}),
                    error.NullValue => std.log.err("Value for function \"{s}\" can't be null\n", .{value.@"0"[0..len]}),
                }
                std.process.exit(1);
            };
            keys_s.bindings.put(key, func) catch @panic("OOM");
            lua.pop(1);
        }
    }
    lua.pop(2);

    var ft: c.FT_Library = undefined;
    defer _ = c.FT_Done_FreeType(ft);

    if (c.FT_Init_FreeType(&ft) == 1) {
        std.log.err("Could not init FreeType Library\n", .{});
    }

    const font_path = getFontPath(font_name) catch |err| {
        switch (err) {
            error.InitError => std.log.err("Failed to init FontConfig", .{}),
            error.FontNotFound => std.log.err("Font {s} not found", .{font_name}),
        }
        std.process.exit(1);
    };

    var face: c.FT_Face = undefined;
    defer _ = c.FT_Done_Face(face);

    if (c.FT_New_Face(ft, @ptrCast(font_path), 0, &face) == 1) {
        std.log.err("Failed to load font\n", .{});
        std.process.exit(1);
    }

    _ = c.FT_Set_Pixel_Sizes(face, 0, 16);
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    for (keys_s.search) |key| {
        keys_s.char_info.put(key, Character.new(face, key)) catch unreachable;
    }

    return keys_s;
}

fn getFontPath(font_name: []const u8) ![]c.FcChar8 {
    if (c.FcInit() != c.FcTrue) return error.InitError;
    defer c.FcFini();

    const config = c.FcInitLoadConfigAndFonts();
    defer c.FcConfigDestroy(config);

    const pattern = c.FcNameParse(@ptrCast(font_name));
    defer c.FcPatternDestroy(pattern);

    _ = c.FcConfigSubstitute(config, pattern, c.FcMatchPattern);
    c.FcDefaultSubstitute(pattern);

    var result: c.FcResult = undefined;
    const match = c.FcFontMatch(config, pattern, &result);

    if (match) |m| {
        var font_path: []c.FcChar8 = undefined;
        if (c.FcPatternGetString(m, c.FC_FILE, 0, @ptrCast(&font_path)) == c.FcResultMatch) {
            return font_path;
        }
    }

    return error.FontNotFound;
}

pub const Function = union(enum) {
    resize: [2]i32,
    move: [2]i32,
    move_selection: [2]i32,
    border_select,
    cancel_selection,
    remove,
    quit,

    pub fn stringToFunction(string: []const u8, value: ?[2]i32) !Function {
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
