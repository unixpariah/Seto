const std = @import("std");
const cairo = @import("cairo");
const render = @import("render.zig");

pub fn main() !void {
    const width_pt: f64 = 640;
    const height_pt: f64 = 480;
    const surface = try cairo.PdfSurface.create("examples/generated/report.pdf", width_pt, height_pt);
    defer surface.destroy();

    surface.setMetadata(cairo.PdfSurface.Metadata.Title, "Some Title");
    surface.setMetadata(cairo.PdfSurface.Metadata.Author, "Some author");
    surface.setMetadata(cairo.PdfSurface.Metadata.CreateDate, "2021-01-28T19:49+02:00");
    surface.setMetadata(cairo.PdfSurface.Metadata.Keywords, "foo,bar");

    const cr = try cairo.Context.create(surface.asSurface());
    defer cr.destroy();

    cr.tagBegin("H1", null);
    cr.moveTo(20, 30);
    cr.showText("Heading 1");
    cr.tagEnd("H1");

    cr.tagBegin(cairo.Context.TagLink, "uri='https://cairographics.org'");
    cr.moveTo(100, 200);
    cr.showText("This is a hyperlink to the Cairo website.");
    cr.tagEnd(cairo.Context.TagLink);
}
