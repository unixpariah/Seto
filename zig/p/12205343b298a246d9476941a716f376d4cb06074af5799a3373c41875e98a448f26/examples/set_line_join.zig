const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/set_line_join/
fn setLineJoin(cr: *cairo.Context) void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    cr.setLineWidth(40.96);

    cr.moveTo(76.8, 84.48);
    cr.relLineTo(51.2, -51.2);
    cr.relLineTo(51.2, 51.2);
    cr.setLineJoin(cairo.Context.LineJoin.Miter); // default
    cr.stroke();

    cr.moveTo(76.8, 161.28);
    cr.relLineTo(51.2, -51.2);
    cr.relLineTo(51.2, 51.2);
    cr.setLineJoin(cairo.Context.LineJoin.Bevel);
    cr.stroke();

    cr.moveTo(76.8, 238.08);
    cr.relLineTo(51.2, -51.2);
    cr.relLineTo(51.2, 51.2);
    cr.setLineJoin(cairo.Context.LineJoin.Round);
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
    setLineJoin(cr);
    try surface.writeToPng("examples/generated/set_line_join.png");
}
