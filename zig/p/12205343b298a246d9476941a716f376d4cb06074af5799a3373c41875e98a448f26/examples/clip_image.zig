const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/clip_image/
fn clipImage(cr: *cairo.Context) !void {
    cr.setSourceRgb(0.0, 0.0, 0.0); // black

    const image = try cairo.ImageSurface.createFromPng("data/romedalen.png");
    defer image.destroy();

    const w = image.getWidth();
    const h = image.getHeight();

    cr.arc(128.0, 128.0, 76.8, 0, 2 * pi);
    cr.clip();
    cr.newPath(); // path not consumed by cr.clip()

    cr.scale(256.0 / @as(f64, @floatFromInt(w)), 256.0 / @as(f64, @floatFromInt(h)));
    cr.setSourceSurface(image.asSurface(), 0, 0);
    cr.paint();
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    try clipImage(cr);
    try surface.writeToPng("examples/generated/clip_image.png");
}
