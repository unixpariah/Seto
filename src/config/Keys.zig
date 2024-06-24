const std = @import("std");
const c = @import("../ffi.zig");

const Lua = @import("ziglua").Lua;

pub const Character = struct {
    texture_id: u32,
    size: [2]i32,
    bearing: [2]i32,
    advance: u32,

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
            .size = .{ @intCast(face.*.glyph.*.bitmap.width), @intCast(face.*.glyph.*.bitmap.rows) },
            .bearing = .{ @intCast(face.*.glyph.*.bitmap_left), @intCast(face.*.glyph.*.bitmap_top) },
            .advance = @intCast(face.*.glyph.*.advance.x),
        };
    }
};

search: []const u8,
bindings: std.AutoHashMap(u8, Function),
char_info: std.AutoHashMap(u8, Character),

const Self = @This();

pub fn new(lua: *Lua, alloc: std.mem.Allocator) Self {
    var keys_s = Self{
        .search = alloc.dupe(u8, "asdfghjkl") catch @panic("OOM"),
        .bindings = std.AutoHashMap(u8, Function).init(alloc),
        .char_info = std.AutoHashMap(u8, Character).init(alloc),
    };

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

    var face: c.FT_Face = undefined;
    defer _ = c.FT_Done_Face(face);

    if (c.FT_New_Face(ft, "/nix/store/09w34ps5vacfih6qn6rh3dkc29ax86fr-dejavu-fonts-minimal-2.37/share/fonts/truetype/DejaVuSans.ttf", 0, &face) == 1) {
        std.log.err("Failed to load font\n", .{});
    }

    _ = c.FT_Set_Pixel_Sizes(face, 0, 48);

    for (keys_s.search) |key| {
        keys_s.char_info.put(key, Character.new(face, key)) catch unreachable;
    }

    var bind_iter = keys_s.bindings.iterator();
    while (bind_iter.next()) |binding| {
        keys_s.char_info.put(binding.key_ptr.*, Character.new(face, binding.key_ptr.*)) catch unreachable;
    }

    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);

    return keys_s;
}

pub const Function = union(enum) {
    border_select,
    resize: [2]i32,
    move: [2]i32,
    move_selection: [2]i32,
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
            const val = value orelse return error.NullValue;
            return .{ .move = .{ val[0], -val[1] } };
        } else if (std.mem.eql(u8, string, "resize")) {
            return .{ .resize = value orelse return error.NullValue };
        } else if (std.mem.eql(u8, string, "move_selection")) {
            const val = value orelse return error.NullValue;
            return .{ .move_selection = .{ val[0], -val[1] } };
        } else if (std.mem.eql(u8, string, "border_select")) {
            return .border_select;
        }

        return error.UnkownFunction;
    }
};
