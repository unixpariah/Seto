const c = @import("ffi");
const zgl = @import("zgl");
const std = @import("std");
const helpers = @import("helpers");
const math = @import("math");

const Config = @import("../Config.zig");
const Color = @import("helpers").Color;
const Font = @import("Font.zig");

const LENGTH: comptime_int = 400;

char_info: []Character,
letter_map: [LENGTH]i32,
transform: [LENGTH]math.Mat4,
color_index: [LENGTH]i32,
alloc: std.mem.Allocator,
index: u32,
texture_array: zgl.Texture,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, search_keys: []const u32, font_family: [:0]const u8) !Self {
    var ft: c.FT_Library = null;
    errdefer _ = c.FT_Done_FreeType(ft);
    if (c.FT_Init_FreeType(&ft) == 1) {
        return error.FreeTypeInitError;
    }

    if (c.FcInit() != c.FcTrue) return error.FontParseError;
    defer c.FcFini();

    const config_fc = c.FcInitLoadConfigAndFonts() orelse return error.FontParseError;
    defer c.FcConfigDestroy(config_fc);

    const pattern = c.FcNameParse(font_family) orelse return error.FontParseError;
    defer c.FcPatternDestroy(pattern);

    if (c.FcConfigSubstitute(config_fc, pattern, c.FcMatchPattern) != c.FcTrue) {
        return error.FontParseError;
    }
    c.FcDefaultSubstitute(pattern);

    var result: c.FcResult = undefined;
    const match = c.FcFontMatch(config_fc, pattern, &result) orelse return error.FontParseError;
    defer c.FcPatternDestroy(match);
    if (result != c.FcResultMatch) return error.FontParseError;

    var font_path: ?[*:0]u8 = null;
    if (c.FcPatternGetString(match, c.FC_FILE, 0, &font_path) != c.FcResultMatch) {
        return error.FontNotFoundError;
    }

    var face: c.FT_Face = null;
    if (c.FT_New_Face(ft, font_path orelse return error.MemoryError, 0, &face) == 1) {
        return error.FontLoadError;
    }
    defer _ = c.FT_Done_Face(face);

    if (c.FT_Set_Pixel_Sizes(face, 256, 256) == 1) {
        return error.FontSizeError;
    }

    zgl.pixelStore(.unpack_alignment, 1);

    var texture_array = zgl.genTexture();
    errdefer texture_array.delete();
    zgl.activeTexture(.texture_0);
    texture_array.bind(.@"2d_array");
    zgl.textureImage3D(.@"2d_array", 0, .r8, 256, 256, search_keys.len, .red, .unsigned_byte, null);

    var max_char = search_keys[0];
    for (search_keys) |char| {
        if (char > max_char) max_char = char;
    }

    var char_info = try alloc.alloc(Character, max_char + 1);
    errdefer alloc.free(char_info);

    @memset(char_info, std.mem.zeroes(Character));

    for (search_keys, 0..) |key, i| {
        char_info[key] = Character.init(face, key, @intCast(i));
    }

    const letter_map = [_]i32{0} ** LENGTH;
    const transform = [_]math.Mat4{math.mat4()} ** LENGTH;
    const color_index = [_]i32{0} ** LENGTH;

    return .{
        .letter_map = letter_map,
        .transform = transform,
        .char_info = char_info,
        .color_index = color_index,
        .alloc = alloc,
        .index = 0,
        .texture_array = texture_array,
    };
}

pub fn place(self: *Self, font_size: f32, text: []const u32, x: f32, y: f32, highlight: bool, shader_program: zgl.Program) void {
    if (text.len == 0) return;

    var move: f32 = 0;
    for (text) |char| {
        const ch = self.char_info[char];

        const x_pos = x + ch.bearing[0] * font_size / 256.0 + move;
        const y_pos = y - ch.bearing[1] * font_size / 256.0;

        self.transform[self.index] = math.transform(font_size, x_pos, y_pos);
        self.letter_map[self.index] = ch.texture_id;
        self.color_index[self.index] = @intFromBool(highlight);

        move += ch.advance[0] * font_size / 256.0;
        self.index += 1;
        if (self.index == LENGTH) {
            self.renderCall(shader_program);
        }
    }
}

pub fn renderCall(self: *Self, shader_program: zgl.Program) void {
    zgl.uniform1iv(shader_program.uniformLocation("colorIndex"), &self.color_index);
    zgl.uniformMatrix4fv(shader_program.uniformLocation("transform"), false, &self.transform);
    zgl.uniform1iv(shader_program.uniformLocation("letterMap"), &self.letter_map);
    zgl.drawArraysInstanced(.triangle_strip, 0, 4, self.index);
    self.index = 0;
}

pub fn getSize(self: *const Self, font_size: f32, text: []const u32) f32 {
    if (text.len == 0) return 0;

    const scale = font_size / 256.0;
    var move: f32 = 0;
    for (text) |char| {
        const ch = self.char_info[char];

        move += ch.advance[0] * scale;
    }

    return move;
}

pub fn deinit(self: *Self) void {
    self.alloc.free(self.char_info);
}

pub const Character = struct {
    texture_id: u8,
    size: [2]f32,
    bearing: [2]f32,
    advance: [2]f32,

    fn init(face: c.FT_Face, key: u32, index: u8) Character {
        if (c.FT_Load_Char(face, key, c.FT_LOAD_RENDER) == 1) {
            std.log.err("Failed to load glyph for character {}\n", .{key});
            std.process.exit(1);
        }

        zgl.texSubImage3D(
            .@"2d_array",
            0,
            0,
            0,
            index,
            face.*.glyph.*.bitmap.width,
            face.*.glyph.*.bitmap.rows,
            1,
            .red,
            .unsigned_byte,
            face.*.glyph.*.bitmap.buffer,
        );

        zgl.texParameter(.@"2d_array", .wrap_s, .clamp_to_border);
        zgl.texParameter(.@"2d_array", .wrap_t, .clamp_to_border);
        zgl.texParameter(.@"2d_array", .min_filter, .linear);
        zgl.texParameter(.@"2d_array", .mag_filter, .linear);

        return .{
            .texture_id = index,
            .size = .{
                @floatFromInt(face.*.glyph.*.bitmap.width),
                @floatFromInt(face.*.glyph.*.bitmap.rows),
            },
            .bearing = .{
                @floatFromInt(face.*.glyph.*.bitmap_left),
                @floatFromInt(face.*.glyph.*.bitmap_top),
            },
            .advance = .{
                @floatFromInt(face.*.glyph.*.advance.x >> 6),
                @floatFromInt(face.*.glyph.*.advance.y >> 6),
            },
        };
    }
};
