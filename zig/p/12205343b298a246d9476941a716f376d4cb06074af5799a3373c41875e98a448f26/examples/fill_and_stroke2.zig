const std = @import("std");
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/fill_and_stroke2/
fn fillAndStroke2(cr: *cairo.Context) void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    // const offset: f64 = -50.0;

    cr.moveTo(128.0, 25.6);
    cr.lineTo(230.4, 230.4);
    cr.relLineTo(-102.4, 0.0);
    cr.curveTo(51.2, 230.4, 51.2, 128.0, 128.0, 128.0);
    cr.closePath();

    cr.moveTo(64.0, 25.6);
    cr.relLineTo(51.2, 51.2);
    cr.relLineTo(-51.2, 51.2);
    cr.relLineTo(-51.2, -51.2);
    cr.closePath();

    cr.setLineWidth(10.0);
    cr.setSourceRgb(0.0, 0.0, 1.0); // blue
    cr.fillPreserve();
    cr.setSourceRgb(0.0, 0.0, 0.0); // black
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
    fillAndStroke2(cr);
    try surface.writeToPng("examples/generated/fill_and_stroke2.png");
}
