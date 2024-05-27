const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/pygobject/pycairo/blob/master/examples/pycairo_examples.ipynb
fn glyphsExample(cr: *cairo.Context) !void {
    cr.selectFontFace("Sans", .Normal, .Normal);

    // draw 0.08 glyphs in 0.10 squares, at(0.01, 0.02) from left corner
    cr.setFontSize(0.08);

    const glyphs = try cairo.Glyph.allocate(100);
    defer cairo.Glyph.free(glyphs);
    for (0..10) |y| {
        for (0..10) |x| {
            const index = y * 10 + x;
            glyphs[index].index = index;
            glyphs[index].x = @as(f64, @floatFromInt(x)) / 10.0 + 0.01;
            glyphs[index].y = @as(f64, @floatFromInt(y)) / 10.0 + 0.08;
        }
    }

    cr.setSourceRgb(0, 0, 0);
    cr.showGlyphs(glyphs);
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
    try surface.writeToPng("examples/generated/glyphs.png");
}
