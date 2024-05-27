const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/pygobject/pycairo/blob/master/examples/pycairo_examples.ipynb
/// https://github.com/pygobject/pycairo/blob/master/examples/cairo_snippets/snippets/hering.py
/// https://gitlab.com/cairo/cairo-demos/-/blob/master/png/hering.c
fn saveAndRestore(cr: *cairo.Context, width: f64, height: f64) void {
    const LINES: usize = 32;
    const MAX_THETA = 0.80 * pi * 2.0;
    const THETA_INC = 2.0 * MAX_THETA / @as(f64, @floatFromInt(LINES - 1));

    cr.save();

    cr.setSourceRgb(0, 0, 0); // black
    cr.setLineWidth(3.0);

    cr.translate(width / 2, height / 2);
    cr.rotate(MAX_THETA);

    var i: usize = 0;
    while (i < LINES) : (i += 1) {
        cr.moveTo(-2 * width, 0);
        cr.lineTo(2 * width, 0);
        cr.stroke();
        cr.rotate(-THETA_INC);
    }

    cr.restore();

    cr.setSourceRgb(1, 0, 0);
    cr.setLineWidth(9.0);

    cr.moveTo(width / 4.0, 0);
    cr.relLineTo(0, height);
    cr.stroke();

    cr.moveTo(3 * width / 4.0, 0);
    cr.relLineTo(0, height);
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
    saveAndRestore(cr, @as(f64, @floatFromInt(width)), @as(f64, @floatFromInt(height)));
    try surface.writeToPng("examples/generated/save_and_restore.png");
}
