const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/image/
fn image(cr: *cairo.Context) !void {
    const surface = try cairo.ImageSurface.createFromPng("data/romedalen.png");
    defer surface.destroy();

    const w: f64 = @floatFromInt(surface.getWidth());
    const h: f64 = @floatFromInt(surface.getHeight());

    cr.translate(128.0, 128.0);
    cr.rotate(45 * pi / 180.0);
    cr.scale(256.0 / w, 256.0 / h);
    cr.translate(-0.5 * w, -0.5 * h);

    cr.setSourceSurface(surface.asSurface(), 0, 0);
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
    try image(cr);
    try surface.writeToPng("examples/generated/image.png");
}
