const std = @import("std");
const c = @import("ffi");
const helpers = @import("helpers");

const Lua = @import("ziglua").Lua;
const Font = @import("Font.zig");

pub const Character = struct {
    texture_id: u32,
    key: u32,
    size: [2]i32,
    bearing: [2]i32,
    advance: [2]u32,

    fn new(face: c.FT_Face, key: u32, font: *const Font, index: u32) Character {
        if (c.FT_Load_Char(face, key, c.FT_LOAD_DEFAULT) == 1) {
            std.log.err("Failed to load glyph for character {}\n", .{key});
            std.process.exit(1);
        }

        if (font.weight) |weight| _ = c.FT_Outline_Embolden(&face.*.glyph.*.outline, @intFromFloat(weight));

        if (c.FT_Render_Glyph(face.*.glyph, c.FT_RENDER_MODE_NORMAL) == 1) {
            std.log.err("Failed to render glyph for character {}\n", .{key});
            std.process.exit(1);
        }

        c.glTexSubImage3D(
            c.GL_TEXTURE_2D_ARRAY,
            0,
            0,
            0,
            @intCast(index),
            @intCast(face.*.glyph.*.bitmap.width),
            @intCast(face.*.glyph.*.bitmap.rows),
            1,
            c.GL_RED,
            c.GL_UNSIGNED_BYTE,
            face.*.glyph.*.bitmap.buffer,
        );

        c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_BORDER);
        c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_BORDER);
        c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D_ARRAY, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

        return .{
            .key = key,
            .texture_id = index,
            .size = .{
                @intCast(face.*.glyph.*.bitmap.width),
                @intCast(face.*.glyph.*.bitmap.rows),
            },
            .bearing = .{
                @intCast(face.*.glyph.*.bitmap_left),
                @intCast(face.*.glyph.*.bitmap_top),
            },
            .advance = .{
                @intCast(face.*.glyph.*.advance.x >> 6),
                @intCast(face.*.glyph.*.advance.y >> 6),
            },
        };
    }
};

letterMap: [400]u32 = undefined,
transform: [400]helpers.Mat4 = undefined,
search: []const u32,
bindings: std.AutoHashMap(u32, Function),
char_info: std.ArrayList(Character),
alloc: std.mem.Allocator,

const Self = @This();

pub fn default(alloc: std.mem.Allocator) Self {
    var bindings = std.AutoHashMap(u32, Function).init(alloc);
    bindings.put('H', .{ .move = .{ -5, 0 } }) catch @panic("OOM");
    bindings.put('J', .{ .move = .{ 0, 5 } }) catch @panic("OOM");
    bindings.put('K', .{ .move = .{ 0, -5 } }) catch @panic("OOM");
    bindings.put('L', .{ .move = .{ 5, 0 } }) catch @panic("OOM");
    bindings.put(8, .remove) catch @panic("OOM");
    bindings.put('b', .border_mode) catch @panic("OOM");

    const keys = [_]u32{ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' };
    const search = alloc.alloc(u32, 9) catch @panic("OOM");
    @memcpy(search, &keys);

    return .{
        .alloc = alloc,
        .search = search,
        .bindings = bindings,
        .char_info = std.ArrayList(Character).init(alloc),
    };
}

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var keys_s = Self.default(alloc);

    _ = lua.pushString("keys");
    _ = lua.getTable(1);
    if (lua.isNil(2)) return keys_s;
    _ = lua.pushString("search");
    _ = lua.getTable(2);
    if (lua.isString(3)) {
        alloc.free(keys_s.search);
        const keys = lua.toString(3) catch unreachable; // Already checked if string
        const utf8_view = std.unicode.Utf8View.init(keys) catch @panic("Failed to initialize utf8 view");

        var buffer = std.ArrayList(u32).init(alloc);
        var iter = utf8_view.iterator();
        while (iter.nextCodepoint()) |codepoint| {
            buffer.append(codepoint) catch @panic("OOM");
        }

        keys_s.search = buffer.toOwnedSlice() catch @panic("OOM");
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

    return keys_s;
}

pub fn loadTextures(self: *Self, font: *const Font) void {
    var ft: c.FT_Library = undefined;
    defer _ = c.FT_Done_FreeType(ft);

    if (c.FT_Init_FreeType(&ft) == 1) @panic("Failed to initialize FreeType");

    var face: c.FT_Face = undefined;
    defer _ = c.FT_Done_Face(face);

    const font_path = getFontPath(self.alloc, font.family) catch |err| {
        switch (err) {
            error.InitError => std.log.err("Failed to initialize FontConfig\n", .{}),
            error.FontNotFound => std.log.err("Font {s} not found\n", .{font.family}),
            else => @panic("OOM"),
        }
        std.process.exit(1);
    };
    defer self.alloc.free(font_path);

    if (c.FT_New_Face(ft, font_path.ptr, 0, &face) == 1) {
        std.log.err("Failed to load font {s}\n", .{font_path});
        std.process.exit(1);
    }

    if (c.FT_Set_Pixel_Sizes(face, 256, 256) == 1) {
        std.log.err("Failed to set font size\n", .{});
        std.process.exit(1);
    }
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    var texture_array: u32 = undefined;
    c.glGenTextures(1, &texture_array);
    c.glActiveTexture(c.GL_TEXTURE0);
    c.glBindTexture(c.GL_TEXTURE_2D_ARRAY, texture_array);
    c.glTexImage3D(
        c.GL_TEXTURE_2D_ARRAY,
        0,
        c.GL_R8,
        256,
        256,
        128,
        0,
        c.GL_RED,
        c.GL_UNSIGNED_BYTE,
        null,
    );

    for (self.search, 0..) |key, i| {
        self.char_info.append(Character.new(face, key, font, @intCast(i))) catch @panic("OOM");
    }

    for (0..400) |i| {
        self.transform[i] = helpers.mat4();
        self.letterMap[i] = 0;
    }

    c.glBindTexture(c.GL_TEXTURE_2D_ARRAY, texture_array);
}

fn getFontPath(alloc: std.mem.Allocator, font_name: [:0]const u8) ![]const u8 {
    if (c.FcInit() != c.FcTrue) return error.InitError;
    defer c.FcFini();

    const config = c.FcInitLoadConfigAndFonts();
    defer c.FcConfigDestroy(config);

    const pattern = c.FcNameParse(font_name);
    defer c.FcPatternDestroy(pattern);

    _ = c.FcConfigSubstitute(config, pattern, c.FcMatchPattern);
    c.FcDefaultSubstitute(pattern);

    var result: c.FcResult = undefined;
    const match = c.FcFontMatch(config, pattern, &result);
    defer c.FcPatternDestroy(match);

    if (match) |m| {
        var font_path: ?[*:0]u8 = undefined;
        if (c.FcPatternGetString(m, c.FC_FILE, 0, &font_path) == c.FcResultMatch) {
            if (font_path) |path| {
                const buffer = try alloc.alloc(u8, std.mem.len(path) + 1);
                @memcpy(buffer, font_path.?);
                return buffer;
            }
        }
    }

    return error.FontNotFound;
}

pub const Function = union(enum) {
    resize: [2]i32,
    move: [2]i32,
    move_selection: [2]i32,
    border_mode,
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
        } else if (std.mem.eql(u8, string, "border_mode")) {
            return .border_mode;
        } else if (std.mem.eql(u8, string, "move")) {
            return .{ .move = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "resize")) {
            return .{ .resize = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "move_selection")) {
            return .{ .move_selection = value orelse return error.NullValue };
        }

        return error.UnkownFunction;
    }
};
