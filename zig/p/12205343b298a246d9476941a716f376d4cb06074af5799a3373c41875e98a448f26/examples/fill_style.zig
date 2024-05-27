const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/fill_style/
fn fillStyle(cr: *cairo.Context) void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    cr.setLineWidth(6);

    cr.rectangle(cairo.Rectangle.init(.{ 12, 12, 232, 70 }));
    cr.newSubPath();
    cr.arc(64, 64, 40, 0, 2 * pi);
    cr.newSubPath();
    cr.arcNegative(192, 64, 40, 0, -2 * pi);

    cr.setFillRule(cairo.Context.FillRule.EvenOdd);
    cr.setSourceRgb(0, 0.7, 0);
    cr.fillPreserve();
    cr.setSourceRgb(0, 0, 0);
    cr.stroke();

    cr.translate(0, 128);
    cr.rectangle(cairo.Rectangle.init(.{ 12, 12, 232, 70 }));
    cr.newSubPath();
    cr.arc(64, 64, 40, 0, 2 * pi);
    cr.newSubPath();
    cr.arcNegative(192, 64, 40, 0, -2 * pi);

    cr.setFillRule(cairo.Context.FillRule.Winding);
    cr.setSourceRgb(0, 0, 0.9);
    cr.fillPreserve();
    cr.setSourceRgb(0, 0, 0);
    cr.stroke();
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    fillStyle(cr);
    try surface.writeToPng("examples/generated/fill_style.png");
}
