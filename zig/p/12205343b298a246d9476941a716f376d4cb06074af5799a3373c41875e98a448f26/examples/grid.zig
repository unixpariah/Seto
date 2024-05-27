const std = @import("std");
const builtin = @import("builtin");
const pi = std.math.pi;
const cairo = @import("cairo");
const setBackground = @import("utils.zig").setBackground;

/// Zig porting of this example from the Perl Cairo tutorial.
/// https://www.lemoda.net/cairo/cairo-tutorial/grid.html
fn drawGrid(cr: *cairo.Context, size: u16, divisions: usize) void {
    cr.setSourceRgb(0.4, 0.4, 1.0); // blue

    var i: usize = 0;
    while (i < divisions) : (i += 1) {
        const s: f64 = @floatFromInt(size);
        const k = s * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(divisions));
        cr.moveTo(k, 0);
        cr.lineTo(k, s);
        cr.moveTo(0, k);
        cr.lineTo(s, k);
    }
    cr.stroke();
}

pub fn main() !void {
    const size: u16 = 400;
    const surface = try cairo.ImageSurface.create(.argb32, size, size);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    const divisions: usize = 10;
    drawGrid(cr, size, divisions);
    try surface.writeToPng("examples/generated/grid.png");
}
