const c = @import("ffi");
const std = @import("std");
const helpers = @import("helpers");
const math = @import("math");

const Config = @import("../Config.zig");
const Color = @import("helpers").Color;
const Font = @import("Font.zig");

const LENGTH: comptime_int = 400;

char_info: []Character,
letter_map: [LENGTH]u32 = undefined,
transform: [LENGTH]math.Mat4 = undefined,
start_color: [LENGTH][4]f32 = undefined,
end_color: [LENGTH][4]f32 = undefined,
deg: [LENGTH]f32 = undefined,
alloc: std.mem.Allocator,
index: u32,

const Self = @This();

pub fn new(alloc: std.mem.Allocator, config: *Config) Self {
    var ft: c.FT_Library = undefined;
    defer _ = c.FT_Done_FreeType(ft);

    if (c.FT_Init_FreeType(&ft) == 1) @panic("Failed to initialize FreeType");

    var face: c.FT_Face = undefined;
    defer _ = c.FT_Done_Face(face);

    const font_path = getFontPath(alloc, config.font.family) catch |err| {
        switch (err) {
            error.InitError => std.log.err("Failed to initialize FontConfig\n", .{}),
            error.FontNotFound => std.log.err("Font {s} not found\n", .{config.font.family}),
            else => @panic("OOM"),
        }
        std.process.exit(1);
    };
    defer alloc.free(font_path);

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
        @intCast(config.keys.search.len),
        0,
        c.GL_RED,
        c.GL_UNSIGNED_BYTE,
        null,
    );

    var char_info = alloc.alloc(Character, config.keys.search.len) catch @panic("OOM");
    for (config.keys.search, 0..) |key, i| {
        char_info[i] = Character.new(face, key, &config.font, @intCast(i));
    }

    var letter_map: [LENGTH]u32 = undefined;
    var transform: [LENGTH]math.Mat4 = undefined;
    for (0..LENGTH) |i| {
        transform[i] = math.mat4();
        letter_map[i] = 0;
    }

    c.glBindTexture(c.GL_TEXTURE_2D_ARRAY, texture_array);

    return .{
        .letter_map = letter_map,
        .transform = transform,
        .char_info = char_info,
        .alloc = alloc,
        .index = 0,
    };
}

pub fn place(self: *Self, text: []const u32, x: f32, y: f32, color: Color, config: *Config, shader_program: *c_uint) void {
    if (text.len == 0) return;

    const scale = config.font.size / 256.0;
    var move: f32 = 0;
    for (text) |char| {
        const ch = blk: {
            for (config.text.char_info) |ch| {
                if (ch.key == char) break :blk ch;
            } else unreachable; // renderText cant be called with a character that is not in char_info
        };

        const bearing: [2]f32 = .{ @floatFromInt(ch.bearing[0]), @floatFromInt(ch.bearing[1]) };
        const x_pos = x + bearing[0] * scale + move;
        const y_pos = y - bearing[1] * scale;

        const scale_mat = math.scale(256 * scale, 256 * scale, 0);
        const translate_mat = math.translate(x_pos, y_pos, 0);

        config.text.transform[self.index] = math.mul(scale_mat, translate_mat);
        config.text.letter_map[self.index] = ch.texture_id;
        config.text.start_color[self.index] = color.start_color;
        config.text.end_color[self.index] = color.end_color;
        config.text.deg[self.index] = color.deg;

        const advance: f32 = @floatFromInt(ch.advance[0]);
        move += advance * scale;
        self.index += 1;
        if (self.index == LENGTH) {
            self.renderCall(shader_program);
        }
    }
}

pub fn renderCall(self: *Self, shader_program: *c_uint) void {
    c.glUniform4fv(
        c.glGetUniformLocation(shader_program.*, "u_startcolor"),
        @intCast(self.index),
        @ptrCast(&self.start_color[0][0]),
    );
    c.glUniform4fv(
        c.glGetUniformLocation(shader_program.*, "u_endcolor"),
        @intCast(self.index),
        @ptrCast(&self.end_color[0][0]),
    );
    c.glUniform1fv(
        c.glGetUniformLocation(shader_program.*, "u_degrees"),
        @intCast(self.index),
        @ptrCast(&self.deg[0]),
    );

    c.glUniformMatrix4fv(
        c.glGetUniformLocation(shader_program.*, "transform"),
        @intCast(self.index),
        c.GL_FALSE,
        @ptrCast(&self.transform[0][0][0]),
    );
    c.glUniform1iv(
        c.glGetUniformLocation(shader_program.*, "letterMap"),
        @intCast(self.index),
        @ptrCast(&self.letter_map[0]),
    );
    c.glDrawArraysInstanced(c.GL_TRIANGLE_STRIP, 0, 4, @intCast(self.index));
    self.index = 0;
}

pub fn destroy(self: *Self) void {
    self.alloc.free(self.char_info);
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
