//! Image Surfaces — Rendering to memory buffers
//!
//! Image surfaces provide the ability to render to memory buffers either
//! allocated by cairo or by the calling code. The supported image formats are
//! those defined in `cairo.Surface.Format`.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html)

const std = @import("std");
const testing = std.testing;

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Mixin = @import("base.zig").Base;
const Format = cairo.Surface.Format;
const ReadFn = cairo.ReadFn;
const CairoError = cairo.CairoError;

/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html)
pub const ImageSurface = opaque {
    pub usingnamespace Mixin(@This());

    /// Creates an image surface of the specified format and dimensions.
    /// Initially the surface contents are set to 0. (Specifically, within each
    /// pixel, each color or alpha channel belonging to format will be 0. The
    /// contents of bits within a pixel, but not belonging to the given format
    /// are undefined).
    ///
    /// **Parameters**
    /// - `format`: format of pixels in the surface to create
    /// - `width`: width of the surface, in pixels
    /// - `height`: height of the surface, in pixels
    ///
    /// **Returns**
    ///
    /// a pointer to the newly created surface.
    ///
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const surface = cairo.ImageSurface.create(.argb32, 100, 100);
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create)
    pub fn create(format: Format, width: u16, height: u16) CairoError!*ImageSurface {
        const image = c.cairo_image_surface_create(format, width, height).?;
        try image.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), image);
        return image;
    }

    /// Creates an image surface for the provided pixel data. The output buffer
    /// must be kept around until the `cairo.ImageSurface` is destroyed or
    /// `surface.finish()` is called on it. The initial contents of `data` will
    /// be used as the initial image contents; you must explicitly clear the
    /// buffer, using, for example, `cr.rectangle()` and `cr.fill()` if you
    /// want it cleared.
    ///
    /// Note that the stride may be larger than `width * bytes_per_pixel` to
    /// provide proper alignment for each pixel and row. This alignment is
    /// required to allow high-speed rendering within cairo. The correct way to
    /// obtain a legal stride value is to call `format.strideForWidth()` on the
    /// desired `format` with maximum image width value, and then use the
    /// resulting stride value to allocate the data and to create the image
    /// surface. See `cairo.Surface.Format.strideForWidth()` for example code.
    ///
    /// **Parameters**
    /// - `data`: a pointer to a buffer supplied by the application in which to
    /// write contents
    /// - `format`: the format of pixels in the buffer
    /// - `width`: the width of the image to be stored in the buffer
    /// - `height`: the height of the image to be stored in the buffer
    /// - `stride`: the number of bytes between the start of rows in the buffer
    /// as allocated. This value should always be computed by
    /// `format.strideForWidth()` before allocating the data buffer.
    ///
    /// **Returns**
    ///
    /// a pointer to the newly created surface.
    ///
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`, see `cairo.Surface.Format.strideForWidth()` for
    /// example code.
    ///
    /// See `cairo.Surface.setUserData()` for a means of attaching a
    /// destroy-notification fallback to the surface if necessary.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create-for-data)
    pub fn createForData(data: [*c]u8, format: Format, width: u16, height: u16, stride: u18) CairoError!*ImageSurface {
        // TODO: check destroy
        const image = c.cairo_image_surface_create_for_data(data, format, width, height, stride).?;
        try image.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), image);
        return image;
    }

    /// Creates a new image surface and initializes the contents to the given
    /// PNG file.
    ///
    /// **Parameters**
    /// - `filename`: name of PNG file to load. On Windows this filename is
    /// encoded in UTF-8.
    ///
    /// **Returns**
    ///
    /// a new `cairo.ImageSurface` initialized with the contents of the PNG
    /// file or fails if any error occurred. Possible errors are:
    /// ```zig
    /// error{ NameTooLong, OutOfMemory, FileNotFound, ReadError, PngError }
    /// ```
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const surface = cairo.ImageSurface.createFromPng("file.png");
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png)
    pub fn createFromPng(filename: []const u8) (CairoError || error{NameTooLong})!*ImageSurface {
        // TODO: allow errors to propagate?
        var buf: [4097]u8 = undefined;
        const filename_z = std.fmt.bufPrintZ(&buf, "{s}", .{filename}) catch return error.NameTooLong;
        const image = c.cairo_image_surface_create_from_png(filename_z.ptr).?;
        try image.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), image);
        return image;
    }

    /// Creates a new image surface from PNG data read incrementally via the
    /// `reader` stream.
    ///
    /// **Parameters**
    /// - `reader`: pointer to a readable object, e.g. `std.io.Reader` or
    /// `std.fs.File` (it should have a `.readAll()` function)
    ///
    /// **Returns**
    ///
    /// a new `cairo.ImageSurface` initialized with the contents of the PNG
    /// file or fails if the data read is not a valid PNG image or memory could
    /// not be allocated for the operation. Possible errors are:
    /// ```zig
    /// error{ OutOfMemory, ReadError, PngError }
    /// ```
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// var file = try std.fs.cwd.open("image.png", .{});
    /// const surface = cairo.ImageSurface.createFromPngStream(&file);
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png-stream)
    pub fn createFromPngStream(reader: anytype) CairoError!*ImageSurface {
        const readFn = cairo.createReadFn(@TypeOf(reader));
        const image = c.cairo_image_surface_create_from_png_stream(readFn, reader).?;
        try image.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), image);
        return image;
    }

    /// Get a pointer to the data of the image surface, for direct inspection
    /// or modification.
    ///
    /// **Returns**
    ///
    /// a pointer to the image data of this surface or fails if
    /// `surface.finish()` has been called or if `surface` is not an
    /// `cairo.ImageSurface`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-data)
    pub fn getData(self: *ImageSurface) CairoError![*]u8 {
        const ptr: ?[*]u8 = c.cairo_image_surface_get_data(self);
        try self.status().toErr();
        return ptr orelse CairoError.NullPointer;
    }

    /// Get the format of the surface.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-format)
    pub fn getFormat(self: *ImageSurface) Format {
        return c.cairo_image_surface_get_format(self);
    }

    /// Get the width of the image surface in pixels.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-width)
    pub fn getWidth(self: *ImageSurface) u16 {
        const width = c.cairo_image_surface_get_width(self);
        return @intCast(width);
    }

    /// Get the height of the image surface in pixels.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-height)
    pub fn getHeight(self: *ImageSurface) u16 {
        const height = c.cairo_image_surface_get_height(self);
        return @intCast(height);
    }

    /// Get the stride of the image surface in bytes.
    ///
    /// The stride is the distance in bytes from the beginning of one row of
    /// the image data to the beginning of the next row.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-stride)
    pub fn getStride(self: *ImageSurface) u18 {
        const stride = c.cairo_image_surface_get_stride(self);
        return @intCast(stride);
    }
};

test "ImageSurface" {
    {
        const surface = try ImageSurface.create(.argb32, 512, 256);
        defer surface.destroy();
        try testing.expectEqual(Format.argb32, surface.getFormat());
        try testing.expectEqual(@as(u16, 512), surface.getWidth());
        try testing.expectEqual(@as(u16, 256), surface.getHeight());
        try testing.expectEqual(@as(u18, 512 * 4), surface.getStride());
        try testing.expect(surface.getType() == .Image);
        try testing.expect(surface.status() == .Success);
    }
}

// test "createFromPngStream" {
//     var file1 = try std.fs.cwd().openFile("out1.png", .{});
//     const surface = try ImageSurface.createFromPngStream(&file1);
//     defer surface.destroy();
//     const ctx = try cairo.Context.create(surface.asSurface());
//     defer ctx.destroy();
//     ctx.rectangle(.{ .x = 500, .y = 300, .width = 80, .height = 80 });
//     ctx.setSourceRgba(0, 0, 0, 0.8);
//     ctx.fill();
//     var file2 = try std.fs.cwd().createFile("out2.png", .{});
//     try surface.writeToPngStream(&file2);
// }
