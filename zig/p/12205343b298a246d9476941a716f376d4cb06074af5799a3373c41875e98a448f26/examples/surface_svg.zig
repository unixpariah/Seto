const std = @import("std");
const cairo = @import("cairo");
const render = @import("render.zig");

pub fn main() !void {
    const width_pt: f64 = 640;
    const height_pt: f64 = 480;
    const surface = try cairo.SvgSurface.create("examples/generated/test-image.svg", width_pt, height_pt);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    render.testImage(cr, width_pt, height_pt);

    const surface2 = try cairo.SvgSurface.create("examples/generated/line-chart.svg", width_pt, height_pt);
    defer surface2.destroy();

    const cr2 = try cairo.Context.create(surface2.asSurface());
    defer cr2.destroy();

    render.lineChart(cr2, width_pt, height_pt);
}
