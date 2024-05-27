const std = @import("std");
const pi = std.math.pi;
const cos = std.math.cos;
const sin = std.math.sin;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/preshing/CairoSample/blob/master/Main.cpp
fn spirograph(cr: *cairo.Context, width: f64, height: f64) void {
    cr.setSourceRgb(0, 0, 0); // black

    const line_width: f64 = 4.0;
    // const half_lw = line_width / 2.0;
    cr.setLineWidth(line_width);

    const xc = width / 2.0;
    const yc = height / 2.0;
    const phi: f64 = 500.0;
    const a: f64 = 70.0;
    const b: f64 = 110.0;

    const k: f64 = 10000;
    var i: f64 = 0;
    while (i < k) : (i += 1) {
        const x = xc + cos(2.0 * pi * i / phi) * a + cos(2.0 * pi * i / k) * b;
        const y = yc + sin(2.0 * pi * i / phi) * a + sin(2.0 * pi * i / k) * b;
        if (i == 0) {
            cr.moveTo(x, y);
        } else {
            cr.lineTo(x, y);
        }
    }
    cr.closePath();
    cr.stroke();
}

pub fn main() !void {
    const width: u16 = 400;
    const height: u16 = 400;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    spirograph(cr, @floatFromInt(width), @floatFromInt(height));
    try surface.writeToPng("examples/generated/spirograph.png");
}
