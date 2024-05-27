const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/pygobject/pycairo/blob/master/examples/pycairo_examples.ipynb
fn glyphsExample(cr: *cairo.Context) !void {
    cr.setLineWidth(0.04);
    cr.selectFontFace("Sans", .Normal, .Normal);

    // draw 0.16 glyphs in 0.20 squares, at (0.02, 0.04) from left corner
    cr.setFontSize(0.16);

    const glyphs = try cairo.Glyph.allocate(25);
    defer cairo.Glyph.free(glyphs);
    const index_offset = 20;
    for (0..5) |y| {
        for (0..5) |x| {
            const index = y * 5 + x;
            glyphs[index].index = index + index_offset;
            glyphs[index].x = @as(f64, @floatFromInt(x)) / 5.0 + 0.02;
            glyphs[index].y = @as(f64, @floatFromInt(y)) / 5.0 + 0.16;
        }
    }

    cr.glyphPath(glyphs);
    cr.setSourceRgb(0.5, 0.5, 1);
    cr.fillPreserve();
    cr.setSourceRgb(0, 0, 0);
    cr.setLineWidth(0.005);
    cr.stroke();
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    // scale context as python example suggests
    cr.scale(@floatFromInt(width), @floatFromInt(height));

    setBackground(cr);
    try glyphsExample(cr);
    try surface.writeToPng("examples/generated/glyphs2.png");
}
