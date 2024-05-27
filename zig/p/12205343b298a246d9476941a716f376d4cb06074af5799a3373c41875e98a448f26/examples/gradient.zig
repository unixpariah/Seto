const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const Rect = cairo.Rectangle;
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/gradient/
fn gradient(cr: *cairo.Context) !void {
    const linear = try cairo.LinearGradientPattern.create(0.0, 0.0, 0.0, 256.0);
    defer linear.destroy();

    linear.addColorStopRgba(1, 0, 0, 0, 1);
    linear.addColorStopRgba(0, 1, 1, 1, 1);
    cr.rectangle(Rect.init(.{ 0, 0, 256, 256 }));
    cr.setSource(linear.asPattern());
    cr.fill();

    const radial = try cairo.RadialGradientPattern.create(115.2, 102.4, 25.6, 102.4, 102.4, 128.0);
    defer radial.destroy();

    radial.addColorStopRgba(0, 1, 1, 1, 1);
    radial.addColorStopRgba(1, 0, 0, 0, 1);
    cr.setSource(radial.asPattern());
    cr.arc(128.0, 128.0, 76.8, 0, 2 * pi);
    cr.fill();
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    try gradient(cr);
    try surface.writeToPng("examples/generated/gradient.png");
}
