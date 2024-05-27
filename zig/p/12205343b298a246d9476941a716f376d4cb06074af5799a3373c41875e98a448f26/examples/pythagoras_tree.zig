const std = @import("std");
const builtin = @import("builtin");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

const m_sqrt_2 = std.math.sqrt(2.0);

// this function fails with cairo.Error.NoCurrentPoint if no current point is set
fn addRectangle(cr: *cairo.Context, size: f64) cairo.CairoError!void {
    if (size < 1) {
        return;
    }

    const point = cr.getCurrentPoint();

    cr.relMoveTo(-size / 2.0, -size / 2.0);
    cr.relLineTo(size, 0);
    cr.relLineTo(0, size);
    cr.relLineTo(-size, 0);
    cr.closePath();

    cr.save();
    cr.translate(-size / 2.0, size);
    cr.moveTo(point.x, point.y);
    cr.rotate(pi / 4.0);
    try addRectangle(cr, size / m_sqrt_2);
    cr.restore();

    cr.save();
    cr.translate(size / 2.0, size);
    cr.moveTo(point.x, point.y);
    cr.rotate(-pi / 4.0);
    try addRectangle(cr, size / m_sqrt_2);
    cr.restore();
    return cr.status().toErr();
}

/// Zig porting of this example in C.
/// https://github.com/freedesktop/cairo/blob/master/perf/micro/pythagoras-tree.c
fn drawPythagorasTree(cr: *cairo.Context, width: f64, height: f64) cairo.CairoError!void {
    const size = 128.0;

    cr.save();
    cr.translate(0, height);
    cr.scale(1, -1);

    cr.moveTo(width / 2.0, size / 2.0);
    try addRectangle(cr, size);
    cr.setSourceRgb(0, 0, 0);
    cr.fill();
    cr.restore();
}

pub fn main() !void {
    const width: u16 = 400;
    const height: u16 = 400;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    try drawPythagorasTree(cr, @as(f64, @floatFromInt(width)), @as(f64, @floatFromInt(height)));
    try surface.writeToPng("examples/generated/pythagoras_tree.png");
}
