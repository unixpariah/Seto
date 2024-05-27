const std = @import("std");
const cairo = @import("cairo");
const render = @import("render.zig");

pub fn main() !void {
    const width: u16 = 640;
    const height: u16 = 480;
    const surface = try cairo.ImageSurface.create(.argb32, width, height);
    defer surface.destroy();

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    render.testImage(cr, width, height);
    try surface.writeToPng("examples/generated/test-image.png");

    render.lineChart(cr, width, height);
    try surface.writeToPng("examples/generated/line-chart.png");
}
