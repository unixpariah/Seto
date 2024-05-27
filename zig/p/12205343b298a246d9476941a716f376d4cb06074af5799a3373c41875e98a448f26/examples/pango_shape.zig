//! Simple example to use pangocairo to render rotated text.
//! https://gitlab.gnome.org/GNOME/pango/-/blob/main/examples/cairoshape.c
const std = @import("std");
const pi = std.math.pi;
const cos = std.math.cos;
const cairo = @import("cairo");
const pango = @import("pango");

const BULLET = "•";

const text =
    \\The GNOME project provides two things:
    \\
    \\  • The GNOME desktop environment
    \\  • The GNOME development platform
    \\  • Planet GNOME
;

const MiniSvg = struct {
    width: f64,
    height: f64,
    path: [:0]const u8,
};

var GnomeFootLogo = MiniSvg{
    .width = 96.2152,
    .height = 118.26,
    .path = "M 86.068,1 C 61.466,0 56.851,35.041 70.691,35.041 C 84.529,35.041 110.671,0 86.068,0 z " ++
        "M 45.217,30.699 C 52.586,31.149 60.671,2.577 46.821,4.374 C 32.976,6.171 37.845,30.249 45.217,30.699 z " ++
        "M 11.445,48.453 C 16.686,46.146 12.12,23.581 3.208,29.735 C -5.7,35.89 6.204,50.759 11.445,48.453 z " ++
        "M 26.212,36.642 C 32.451,35.37 32.793,9.778 21.667,14.369 C 10.539,18.961 19.978,37.916 26.212,36.642 L 26.212,36.642 z " ++
        "M 58.791,93.913 C 59.898,102.367 52.589,106.542 45.431,101.092 C 22.644,83.743 83.16,75.088 79.171,51.386 C 75.86,31.712 15.495,37.769 8.621,68.553 C 3.968,89.374 27.774,118.26 52.614,118.26 C 64.834,118.26 78.929,107.226 81.566,93.248 C 83.58,82.589 57.867,86.86 58.791,93.913 L 58.791,93.913 z ",
};

fn readFloatPair(reader: anytype, x: *f64, y: *f64) !void {
    var floatBuf: [10]u8 = undefined;
    const f1 = try reader.readUntilDelimiter(&floatBuf, ',');
    x.* = try std.fmt.parseFloat(f64, f1);
    const f2 = try reader.readUntilDelimiter(&floatBuf, ' ');
    y.* = try std.fmt.parseFloat(f64, f2);
}

fn miniSvgRender(shape: *const MiniSvg, cr: *cairo.Context, do_path: bool) !void {
    const point = cr.getCurrentPoint();
    var x: f64 = point.x;
    var y: f64 = point.y;
    cr.translate(x, y);

    var p = std.io.fixedBufferStream(shape.path);
    const reader = p.reader();
    var op: u8 = undefined;

    while (p.pos != p.buffer.len) {
        op = try reader.readByte();
        if (!try reader.isBytes(" ")) return error.MalformedMiniSvg;
        switch (op) {
            'M' => {
                try readFloatPair(reader, &x, &y);
                cr.moveTo(x, y);
            },
            'L' => {
                try readFloatPair(reader, &x, &y);
                cr.lineTo(x, y);
            },
            'C' => {
                var curve: [6]f64 = undefined;
                try readFloatPair(reader, &curve[0], &curve[1]);
                try readFloatPair(reader, &curve[2], &curve[3]);
                try readFloatPair(reader, &curve[4], &curve[5]);
                cr.curveTo(curve[0], curve[1], curve[2], curve[3], curve[4], curve[5]);
            },
            'z' => cr.closePath(),
            else => std.debug.panic("Invalid MiniSvg operation '{c}'\n", .{op}),
        }
    }
    if (!do_path) cr.fill();
}

fn miniSvgShapeRenderer(cr: *cairo.Context, attr: *pango.AttrShape, do_path: c_int, _: ?*anyopaque) callconv(.C) void {
    const shape: *MiniSvg = @alignCast(@ptrCast(attr.data.?));
    const scale_x = @as(f64, @floatFromInt(attr.ink_rect.width)) / (pango.SCALE * shape.width);
    const scale_y = @as(f64, @floatFromInt(attr.ink_rect.height)) / (pango.SCALE * shape.height);
    cr.relMoveTo(
        @as(f64, @floatFromInt(attr.ink_rect.x)) / pango.SCALE,
        @as(f64, @floatFromInt(attr.ink_rect.y)) / pango.SCALE,
    );
    cr.scale(scale_x, scale_y);
    miniSvgRender(shape, cr, do_path != 0) catch unreachable;
}

fn getLayout(cr: *cairo.Context) !*pango.Layout {
    const ink_rect = pango.Rectangle.init(1 * pango.SCALE, -11 * pango.SCALE, 8 * pango.SCALE, 10 * pango.SCALE);
    const logical_rect = pango.Rectangle.init(0 * pango.SCALE, -12 * pango.SCALE, 10 * pango.SCALE, 12 * pango.SCALE);

    // Create a PangoLayout, set the font and text
    const layout: *pango.Layout = try cr.createLayout();
    const pango_context = try layout.getContext();
    pango_context.setShapeRenderer(@ptrCast(&miniSvgShapeRenderer), null, null);
    layout.setText(text);

    const attrs = try pango.AttrList.create();
    defer attrs.destroy();

    // Set gnome shape attributes for all bullets
    var p: []const u8 = text;
    var offset: usize = 0;
    while (std.mem.indexOf(u8, p, BULLET)) |index| {
        offset += index;
        const end = offset + BULLET.len;
        const attr = try pango.AttrShape.newWithData(
            &ink_rect,
            &logical_rect,
            &GnomeFootLogo,
            null,
            null,
        );

        attr.start_index = @intCast(offset);
        attr.end_index = @intCast(end);
        attrs.insert(attr);
        offset = end;
        p = text[offset..];
    }

    layout.setAttributes(attrs);
    return layout;
}

fn drawText(cr: *cairo.Context, width: ?*i32, height: ?*i32) !void {
    const layout = try getLayout(cr);

    // Adds a fixed 10-pixel margin on the sides.
    if (width != null or height != null) {
        layout.getPixelSize(width, height);
        if (width) |w| w.* += 20;
        if (height) |h| h.* += 20;
    }

    cr.moveTo(10, 10);
    cr.showLayout(layout);

    layout.destroy();
}

pub fn main() !void {
    var surface: *cairo.ImageSurface = undefined;
    var context: *cairo.Context = undefined;
    var width: i32 = undefined;
    var height: i32 = undefined;

    // First create and use a 0x0 surface, to measure how large the final
    // surface needs to be
    surface = try cairo.ImageSurface.create(.argb32, 0, 0);
    context = try cairo.Context.create(surface.asSurface());
    try drawText(context, &width, &height);
    context.destroy();
    surface.destroy();

    // Now create the final surface and draw to it
    surface = try cairo.ImageSurface.create(.argb32, @intCast(width), @intCast(height));
    defer surface.destroy();
    context = try cairo.Context.create(surface.asSurface());
    defer context.destroy();

    context.setSourceRgb(1, 1, 1);
    context.paint();
    context.setSourceRgb(0, 0, 0.5);
    try drawText(context, null, null);

    // Write out the surface as PNG
    try surface.writeToPng("examples/generated/pango_shape.png");
}
