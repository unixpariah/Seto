const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/clip/
fn clip(cr: *cairo.Context) void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    cr.arc(128.0, 128.0, 76.8, 0, 2 * pi);
    cr.clip();

    // current path is not consumed by cr.clip()
    cr.newPath();
    cr.rectangle(cairo.Rectangle.init(.{ 0, 0, 256, 256 }));
    cr.fill();
    cr.setSourceRgb(0, 1, 0);
    cr.moveTo(0, 0);
    cr.lineTo(256, 256);
    cr.moveTo(256, 0);
    cr.lineTo(0, 256);
    cr.setLineWidth(10.0);
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
    clip(cr);
    try surface.writeToPng("examples/generated/clip.png");
}
