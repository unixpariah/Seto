const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/multi_segment_caps/
fn multiSegmentCaps(cr: *cairo.Context) void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    cr.moveTo(50.0, 75.0);
    cr.lineTo(200.0, 75.0);

    cr.moveTo(50.0, 125.0);
    cr.lineTo(200.0, 125.0);

    cr.moveTo(50.0, 175.0);
    cr.lineTo(200.0, 175.0);

    cr.setLineWidth(30.0);
    cr.setLineCap(cairo.Context.LineCap.Round);
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
    multiSegmentCaps(cr);
    try surface.writeToPng("examples/generated/multi_segment_caps.png");
}
