//! Simple example to use pangocairo to render rotated text.
//! https://gitlab.gnome.org/GNOME/pango/-/blob/master/examples/cairosimple.c
const std = @import("std");
const pi = std.math.pi;
const cos = std.math.cos;
const cairo = @import("cairo");
const pango = @import("pango");

const RADIUS: f64 = 300;
const TWEAKABLE_SCALE: f64 = 0.8;
const FONT_WITH_MANUAL_SIZE = "Times new roman,Sans";
// const FONT_WITH_MANUAL_SIZE = "Cantarell Italic Light 15 @wght=200";
const FONT_SIZE: f64 = 36;
const DEVICE_DPI: f64 = 72;
const N_WORDS: usize = 8;

fn drawText(cr: *cairo.Context) !void {
    cr.translate(RADIUS / TWEAKABLE_SCALE, RADIUS / TWEAKABLE_SCALE);

    const layout: *pango.Layout = try cr.createLayout();
    defer layout.destroy();

    layout.setText("Hello\nПривет\nこんにちは\n你好\nسَلام"); // arabic is written from right

    const desc = try pango.FontDescription.fromString(FONT_WITH_MANUAL_SIZE);
    defer desc.free();

    const scale: f64 = pango.SCALE;
    desc.setAbsoluteSize(FONT_SIZE * DEVICE_DPI * scale / (72.0 / TWEAKABLE_SCALE));
    layout.setFontDescription(desc);

    // Draw the layout N_WORDS times in a circle
    var i: usize = 0;
    while (i < N_WORDS) : (i += 1) {
        const angle: f64 = (360.0 * @as(f64, @floatFromInt(i))) / @as(f64, @floatFromInt(N_WORDS));

        cr.save();
        // gradient from red at angle == 60 to blue at angle == 240
        const red = (1.0 + cos((angle - 60.0) * pi / 180.0)) / 2.0;
        cr.setSourceRgb(red, 0, 1.0 - red);
        cr.rotate(angle * pi / 180.0);
        // tell Pango to re-layout the text with the new transformation
        cr.updateLayout(layout);
        var width: i32 = undefined;
        layout.getSize(&width, null);
        cr.moveTo(-(@as(f64, @floatFromInt(width)) / scale / 2.0), -(RADIUS / TWEAKABLE_SCALE));
        cr.showLayout(layout);
        cr.restore();
    }
}

pub fn main() !void {
    const surface = try cairo.ImageSurface.create(.argb32, 2.0 * RADIUS, 2.0 * RADIUS);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    cr.scale(TWEAKABLE_SCALE, TWEAKABLE_SCALE);
    cr.setSourceRgb(1.0, 1.0, 1.0); // white
    cr.paint();
    try drawText(cr);
    try surface.writeToPng("examples/generated/pango_simple.png");
}
