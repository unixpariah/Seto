const std = @import("std");
const pi = std.math.pi;
const cairo = @import("cairo");
const Rect = cairo.Rectangle;
const setBackground = @import("utils.zig").setBackground;

/// https://github.com/pygobject/pycairo/blob/master/examples/pycairo_examples.ipynb
fn groupExample(cr: *cairo.Context) !void {
    cr.setSourceRgb(0.8, 0.8, 0.8); // gray
    cr.rectangle(Rect.init(.{ 25.6, 25.6, 153.6, 153.6 }));
    cr.fill();

    const red_pattern = try cairo.SolidPattern.createRgb(1, 0, 0);
    defer red_pattern.destroy();

    const black_pattern = try cairo.SolidPattern.createRgb(0, 0, 0);
    defer black_pattern.destroy();

    cr.pushGroup();
    // define a red rectangle
    cr.setSource(red_pattern.asPattern());
    cr.rectangle(Rect.init(.{ 76.8, 76.8, 153.6, 153.6 }));
    // fill the path we have just defined (i.e. the rectangle) and preserve it
    cr.fillPreserve();
    // define a black rectangular frame
    cr.setLineWidth(8.0);
    cr.setSource(black_pattern.asPattern());
    cr.stroke();
    cr.popGroupToSource();
    // paint the entire group with a semi-transparent alpha channel
    cr.paintWithAlpha(0.5);
}

pub fn main() !void {
    const width: u16 = 256;
    const height: u16 = 256;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    setBackground(cr);
    try groupExample(cr);
    try surface.writeToPng("examples/generated/group.png");
}
