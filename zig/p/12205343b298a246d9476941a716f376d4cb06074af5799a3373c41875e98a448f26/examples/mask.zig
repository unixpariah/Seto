const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/pygobject/pycairo/blob/master/examples/pycairo_examples.ipynb
fn maskExample(cr: *cairo.Context) !void {
    const pattern = try cairo.LinearGradientPattern.create(0, 0, 256, 256);
    defer pattern.destroy();

    pattern.addColorStopRgb(0, 0, 0.3, 0.8);
    pattern.addColorStopRgb(1, 0, 0.8, 0.3);

    const mask = try cairo.RadialGradientPattern.create(128, 128, 64, 128, 128, 128);
    defer mask.destroy();

    mask.addColorStopRgba(0, 0, 0, 0, 1);
    mask.addColorStopRgba(0.5, 0, 0, 0, 0);

    cr.setSource(pattern.asPattern());
    cr.mask(mask.asPattern());
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    try maskExample(cr);
    try surface.writeToPng("examples/generated/mask.png");
}
