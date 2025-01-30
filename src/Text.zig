const max_instances = @import("max_instances").max_instances;
const c = @import("ffi");
const zgl = @import("zgl");
const std = @import("std");
const helpers = @import("helpers");
const math = @import("math");

const Config = @import("Config.zig");
const Color = @import("helpers").Color;
const Font = @import("config/Font.zig");

atlas: FontAtlas,
letter_map: [max_instances]i32,
transform: [max_instances]math.Mat4,
color_index: [max_instances]i32,
alloc: std.mem.Allocator,
index: u32,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, search_keys: []const u32, font_family: [:0]const u8) !Self {
    var ft: c.FT_Library = undefined;
    if (c.FT_Init_FreeType(&ft) != 0) return error.FreeTypeInitError;

    const fc_initialized = c.FcInit() == c.FcTrue;
    defer if (fc_initialized) c.FcFini();
    if (!fc_initialized) return error.FontParseError;

    const config_fc = c.FcInitLoadConfigAndFonts() orelse return error.FontParseError;
    defer c.FcConfigDestroy(config_fc);

    const pattern = c.FcNameParse(font_family) orelse return error.FontParseError;
    defer c.FcPatternDestroy(pattern);

    if (c.FcConfigSubstitute(config_fc, pattern, c.FcMatchPattern) != c.FcTrue) {
        return error.FontParseError;
    }
    c.FcDefaultSubstitute(pattern);

    var result: c.FcResult = undefined;
    const match = c.FcFontMatch(config_fc, pattern, &result) orelse return error.FontMatchFailed;
    defer c.FcPatternDestroy(match);
    if (result != c.FcResultMatch) return error.FontParseError;

    var font_path: ?[*:0]u8 = null;
    if (c.FcPatternGetString(match, c.FC_FILE, 0, &font_path) != c.FcResultMatch) {
        return error.FontNotFoundError;
    }

    var face: c.FT_Face = null;
    if (c.FT_New_Face(ft, font_path, 0, &face) != 0) {
        return error.FontLoadError;
    }
    defer _ = c.FT_Done_Face(face);

    if (c.FT_Set_Pixel_Sizes(face, 256, 256) != 0) {
        return error.FontSizeError;
    }

    return .{
        .letter_map = [_]i32{0} ** max_instances,
        .transform = [_]math.Mat4{math.mat4()} ** max_instances,
        .color_index = [_]i32{0} ** max_instances,
        .alloc = alloc,
        .index = 0,
        .atlas = try FontAtlas.init(alloc, face, search_keys),
    };
}

pub fn deinit(self: *Self) void {
    self.atlas.deinit();
}

pub fn place(self: *Self, font_size: f32, text: []const u32, x: f32, y: f32, highlight: bool, shader_program: zgl.Program) void {
    if (text.len == 0) return;

    var move: f32 = 0;
    const scale = font_size / 256.0;
    for (text) |char| {
        const ch = self.atlas.char_info.get(char) orelse continue;

        const x_pos = x + ch.bearing[0] * scale + move;
        const y_pos = y - ch.bearing[1] * scale;

        self.transform[self.index] = math.transform(font_size, x_pos, y_pos);
        self.letter_map[self.index] = ch.texture_id;
        self.color_index[self.index] = @intFromBool(highlight);

        move += ch.advance[0] * scale;
        self.index += 1;
        if (self.index >= max_instances) self.renderCall(shader_program);
    }
}

pub fn renderCall(self: *Self, shader_program: zgl.Program) void {
    zgl.uniform1iv(shader_program.uniformLocation("colorIndex"), &self.color_index);
    zgl.uniformMatrix4fv(shader_program.uniformLocation("transform"), false, &self.transform);
    zgl.uniform1iv(shader_program.uniformLocation("letterMap"), &self.letter_map);
    zgl.drawArraysInstanced(.triangle_strip, 0, 4, self.index);
    self.index = 0;
}

pub fn getSize(self: *const Self, font_size: f32, text: []const u32) struct { width: f32, height: f32 } {
    if (text.len == 0) return .{ .width = 0, .height = 0 };

    const scale = font_size / 256.0;
    var width: f32 = 0;
    var max_ascent: f32 = 0;
    var max_descent: f32 = 0;

    for (text) |char| {
        const ch = self.atlas.char_info.get(char) orelse continue;

        width += ch.advance[0] * scale;

        const ascent = ch.bearing[1] * scale;
        const descent = (ch.size[1] - ch.bearing[1]) * scale;

        max_ascent = @max(max_ascent, ascent);
        max_descent = @max(max_descent, descent);
    }

    return .{ .width = width, .height = max_ascent + max_descent };
}

const FontAtlas = struct {
    char_info: std.AutoHashMap(u32, Character),
    texture_array: zgl.Texture,

    fn init(alloc: std.mem.Allocator, face: c.FT_Face, keys: []const u32) !FontAtlas {
        zgl.pixelStore(.unpack_alignment, 1);

        var texture_array = zgl.genTexture();
        zgl.activeTexture(.texture_0);
        texture_array.bind(.@"2d_array");

        const padding = 4;

        var max_width: usize = 0;
        var max_height: usize = 0;
        for (keys) |key| {
            const size = try Character.size(face, key, padding);
            max_width = @max(max_width, size[0]);
            max_height = @max(max_height, size[1]);
        }

        zgl.texStorage3D(.@"2d_array", 5, .r8, @max(max_height, max_width), @max(max_height, max_width), keys.len);

        var char_info = std.AutoHashMap(u32, Character).init(alloc);
        for (keys, 0..) |key, i| {
            if (key > 0x10FFFF) return error.InvalidUnicodeCodepoint;
            if (key >= 0xD800 and key <= 0xDFFF) return error.SurrogateCodepoint;

            try char_info.put(key, try Character.init(face, key, @intCast(i), padding));
        }

        zgl.generateMipmap(.@"2d_array");

        return .{
            .char_info = char_info,
            .texture_array = texture_array,
        };
    }

    pub fn deinit(self: *FontAtlas) void {
        self.char_info.deinit();
        self.texture_array.delete();
    }
};

pub const Character = struct {
    texture_id: u16,
    size: [2]f32,
    bearing: [2]f32,
    advance: [2]f32,

    fn size(face: c.FT_Face, key: u32, padding: comptime_int) ![2]usize {
        const ft_load_flags = c.FT_LOAD_DEFAULT | c.FT_LOAD_NO_BITMAP;
        const ft_render_mode = c.FT_RENDER_MODE_SDF;

        if (c.FT_Load_Char(face, key, ft_load_flags) != 0) {
            std.log.err("Failed to load glyph for character {}\n", .{key});
            return error.GlyphLoadError;
        }

        if (c.FT_Render_Glyph(face.*.glyph, ft_render_mode) != 0) {
            return error.GlyphRenderError;
        }

        const bitmap = &face.*.glyph.*.bitmap;

        const padded_width = bitmap.width + padding * 2;
        const padded_rows = bitmap.rows + padding * 2;

        return .{ padded_width, padded_rows };
    }

    fn init(face: c.FT_Face, key: u32, index: u8, padding: comptime_int) !Character {
        const padded_size = try Character.size(face, key, padding);
        const bitmap = &face.*.glyph.*.bitmap;

        var padded_buffer = try std.heap.c_allocator.alloc(u8, padded_size[0] * padded_size[1]);
        defer std.heap.c_allocator.free(padded_buffer);
        @memset(padded_buffer, 0);

        for (0..@intCast(bitmap.rows)) |y| {
            const src_row = y * bitmap.width;
            const dst_row = (y + padding) * padded_size[0] + padding;
            @memcpy(
                padded_buffer[dst_row .. dst_row + bitmap.width],
                bitmap.buffer[src_row .. src_row + bitmap.width],
            );
        }

        zgl.texSubImage3D(
            .@"2d_array",
            0,
            0,
            0,
            index,
            padded_size[0],
            padded_size[1],
            1,
            .red,
            .unsigned_byte,
            padded_buffer.ptr,
        );

        zgl.texParameter(.@"2d_array", .wrap_s, .clamp_to_edge);
        zgl.texParameter(.@"2d_array", .wrap_t, .clamp_to_edge);
        zgl.texParameter(.@"2d_array", .min_filter, .linear_mipmap_linear);
        zgl.texParameter(.@"2d_array", .mag_filter, .linear);
        zgl.texParameter(.@"2d_array", .max_level, 4);

        return .{
            .texture_id = index,
            .size = .{
                @floatFromInt(bitmap.width),
                @floatFromInt(bitmap.rows),
            },
            .bearing = .{
                @floatFromInt(face.*.glyph.*.bitmap_left),
                @floatFromInt(face.*.glyph.*.bitmap_top),
            },
            .advance = .{
                @as(f32, @floatFromInt(face.*.glyph.*.advance.x)) / 64.0,
                @as(f32, @floatFromInt(face.*.glyph.*.advance.y)) / 64.0,
            },
        };
    }
};
