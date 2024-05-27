const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const Content = cairo.Content;
const Operator = cairo.Context.Operator;
const Rectangle = cairo.Rectangle;
const setBackground = @import("utils.zig").setBackground;

fn draw(cr: *cairo.Context, width: u16, height: u16, x: f64, y: f64, rw: f64, rh: f64, op: Operator) !void {
    const surface = try cr.getTarget();

    const red = try surface.createSimilar(Content.ColorAlpha, width, height);
    defer red.destroy();
    const blue = try surface.createSimilar(Content.ColorAlpha, width, height);
    defer blue.destroy();

    const red_cr = try cairo.Context.create(red);
    defer red_cr.destroy();

    red_cr.setSourceRgba(0.7, 0, 0, 0.8);
    red_cr.rectangle(Rectangle.init(.{ x, y, rw, rh }));
    red_cr.fill();

    const blue_cr = try cairo.Context.create(blue);
    defer blue_cr.destroy();

    blue_cr.setSourceRgba(0, 0, 0.9, 0.4);
    blue_cr.rectangle(Rectangle.init(.{ x + 40.0, y + 30.0, rw, rh }));
    blue_cr.fill();

    red_cr.setOperator(op);

    // use the `blue` cairo.Surface to create a cairo.Pattern, then set that
    // pattern as the source for the `red_cr` cairo.Context.
    red_cr.setSourceSurface(blue, 0, 0);
    red_cr.paint();

    cr.setSourceSurface(red, 0, 0);
    cr.paint();

    cr.moveTo(x, y);
    cr.setSourceRgb(0.0, 0.0, 0.0);
    cr.showText(@tagName(op));
}

const OpAndName = struct {
    op: Operator,
    name: []const u8,
};

/// https://www.cairographics.org/operators/
fn drawAll(cr: *cairo.Context, width: u16, height: u16) !void {
    const operators = [_]Operator{ .Add, .Atop, .Clear, .ColorBurn, .ColorDodge, .Darken, .Dest, .DestAtop, .DestIn, .DestOut, .DestOver, .Difference, .Exclusion, .HardLight, .HslColor, .HslHue, .HslLuminosity, .HslSaturation, .In, .Lighten, .Multiply, .Out, .Over, .Overlay, .Saturate, .Screen, .SoftLight, .Source, .Xor };
    const k: usize = 6; // figures per row
    const rw = 120.0; // rectangle width
    const rh = 90.0; // rectangle height
    const margin = 20.0;
    const padding = 60.0;
    for (operators, 0..) |op, i| {
        const row = @divTrunc(i, k);
        const col = @mod(i, k);
        const pad_x = padding * @as(f64, @floatFromInt(col));
        const pad_y = padding * @as(f64, @floatFromInt(row));
        const x = margin + rw * @as(f64, @floatFromInt(col)) + pad_x;
        const y = margin + (rh * @as(f64, @floatFromInt(row))) + pad_y;
        try draw(cr, width, height, x, y, rw, rh, op);
    }
}

pub fn main() !void {
    const width: u16 = 1200;
    const height: u16 = 800;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    cr.selectFontFace("Sans", cairo.FontFace.FontSlant.Normal, cairo.FontFace.FontWeight.Normal);
    cr.setFontSize(18.0);

    setBackground(cr);
    try drawAll(cr, width, height);
    try surface.writeToPng("examples/generated/compositing.png");
}
