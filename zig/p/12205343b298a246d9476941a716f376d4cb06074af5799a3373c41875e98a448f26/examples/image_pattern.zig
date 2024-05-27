const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const Rect = cairo.Rectangle;
const setBackground = @import("utils.zig").setBackground;

/// https://www.cairographics.org/samples/imagepattern/
fn imagePattern(cr: *cairo.Context) !void {
    const image = try cairo.ImageSurface.createFromPng("data/romedalen.png");
    defer image.destroy();

    const w: f64 = @floatFromInt(image.getWidth());
    const h: f64 = @floatFromInt(image.getHeight());

    const pattern = try cairo.SurfacePattern.createFor(image.asSurface());
    defer pattern.destroy();

    pattern.setExtend(cairo.Pattern.Extend.Repeat);

    cr.translate(128.0, 128.0);
    cr.rotate(pi / 4.0);
    cr.scale(1.0 / @sqrt(2.0), 1.0 / std.math.sqrt(2.0));
    cr.translate(-128.0, -128.0);

    const sx = w / 256.0 * 5.0;
    const sy = h / 256.0 * 5.0;

    const matrix = cairo.Matrix.scaling(sx, sy);
    pattern.setMatrix(&matrix);

    cr.setSource(pattern.asPattern());
    cr.rectangle(Rect.init(.{ 0, 0, 256, 256 }));
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

    try imagePattern(cr);
    try surface.writeToPng("examples/generated/image_pattern.png");
}
