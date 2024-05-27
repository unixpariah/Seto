//! Win32 Surfaces — Microsoft Windows surface support

const safety = @import("safety");

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const CairoError = cairo.CairoError;

const Mixin = @import("base.zig").Base;

/// The Microsoft Windows surface is used to render cairo graphics to Microsoft
/// Windows windows, bitmaps, and printing device contexts.
///
/// The surface returned by `cairo.Win32Surface.createPrintingSurface()` is of
/// surface type `cairo.Surface.Type.Win32Printing` and is a multi-page vector
/// surface type.
///
/// The surface returned by the other win32 constructors is of surface type
/// `cairo.Surface.Type.Win32` and is a raster surface type.
pub const Win32Surface = opaque {
    pub usingnamespace Mixin(@This());

    /// Creates a cairo surface that targets the given DC. The DC will be
    /// queried for its initial clip extents, and this will be used as the size
    /// of the cairo surface. The resulting surface will always be of format
    /// `cairo.Surface.Format.rgb24`; should you need another surface format,
    /// you will need to create one through
    /// `cairo.Win32Surface.createWithFormat()` or
    /// `cairo.Win32Surface.createWithDib()`.
    ///
    /// **Parameters**
    /// - `hdc`: the DC to create a surface for.
    ///
    /// **Returns**
    ///
    /// the newly created surface
    pub fn create(hdc: *anyopaque) CairoError!*Win32Surface {
        const ptr = c.cairo_win32_surface_create(hdc) orelse return CairoError.Win32GdiError;
        try ptr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Creates a device-independent-bitmap surface not associated with any
    /// particular existing surface or device context. The created bitmap will
    /// be uninitialized.
    ///
    /// **Parameters**
    /// - `format`: format of pixels in the surface to create
    /// - `width`: width of the surface, in pixels
    /// - `height`: height of the surface, in pixels
    ///
    /// **Returns**
    ///
    /// the newly created surface.
    pub fn createWithDib(format: cairo.Surface.Format, width: i32, height: i32) CairoError!*Win32Surface {
        const ptr = c.cairo_win32_surface_create_with_dib(format, @intCast(width), @intCast(height)) orelse return CairoError.Win32GdiError;
        try ptr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Creates a device-dependent-bitmap surface not associated with any
    /// particular existing surface or device context. The created bitmap will
    /// be uninitialized.
    ///
    /// **Parameters**
    /// - `hdc: a DC compatible with the surface to create
    /// - `format`: format of pixels in the surface to create
    /// - `width`: width of the surface, in pixels
    /// - `height`: height of the surface, in pixels
    ///
    /// **Returns**
    ///
    /// the newly created surface.
    pub fn createWithDdb(hdc: ?*anyopaque, format: cairo.Surface.Format, width: i32, height: i32) CairoError!*Win32Surface {
        const ptr = c.cairo_win32_surface_create_with_ddb(hdc, format, @intCast(width), @intCast(height)) orelse return CairoError.Win32GdiError;
        try ptr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Creates a cairo surface that targets the given DC. The DC will be
    /// queried for its initial clip extents, and this will be used as the size
    /// of the cairo surface.
    ///
    /// Supported formats are: `cairo.Surface.Format.argb32`,
    /// `cairo.Surface.Format.rgb24`.
    ///
    /// Note: `format` only tells cairo how to draw on the surface, not what
    /// the format of the surface is. Namely, cairo does not (and cannot) check
    /// that hdc actually supports alpha-transparency.
    ///
    /// **Parameters**
    /// - `hdc: the DC to create a surface for
    /// - `format`: format of pixels in the surface to create
    ///
    /// **Returns**
    ///
    /// the newly created surface.
    pub fn createWithFormat(hdc: ?*anyopaque, format: cairo.Surface.Format) CairoError!*Win32Surface {
        const ptr = c.cairo_win32_surface_create_with_format(hdc, format) orelse return CairoError.Win32GdiError;
        try ptr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Creates a cairo surface that targets the given DC. The DC will be
    /// queried for its initial clip extents, and this will be used as the size
    /// of the cairo surface. The DC should be a printing DC; antialiasing will
    /// be ignored, and GDI will be used as much as possible to draw to the
    /// surface.
    ///
    /// The returned surface will be wrapped using the paginated surface to
    /// provide correct complex rendering behaviour; `cairo.Surface.showPage()`
    /// and associated methods must be used for correct output.
    ///
    /// **Parameters**
    /// - `hdc`: the DC to create a surface for.
    ///
    /// **Returns**
    ///
    /// the newly created surface
    pub fn createPrintingSurface(hdc: *anyopaque) CairoError!*Win32Surface {
        const ptr = c.cairo_win32_printing_surface_create(hdc) orelse return CairoError.Win32GdiError;
        try ptr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Returns the HDC associated with this surface, or `null` if none.
    ///
    /// A call to `cairo.Surface.flush()` is required before using the HDC to
    /// ensure that all pending drawing operations are finished and to restore
    /// any temporary modification cairo has made to its state. A call to
    /// `cairo.Surface.markDirty()` is required after the state or the content
    /// of the HDC has been modified.
    ///
    /// **Returns**
    ///
    /// HDC or `null` if no HDC available.
    pub fn getDc(self: *Win32Surface) ?*anyopaque {
        return c.cairo_win32_surface_get_dc(self);
    }

    /// Returns a `cairo.ImageSurface` that refers to the same bits as the DIB
    /// of the Win32 surface.
    ///
    /// **Returns**
    ///
    /// a `cairo.ImageSurface` (owned by the `cairo.Win32Surface`), or
    /// `error.SurfaceTypeMismatch` if the win32 surface is not a DIB.
    pub fn getImage(self: *Win32Surface) CairoError!*cairo.ImageSurface {
        return c.cairo_win32_surface_get_image(self) orelse CairoError.SurfaceTypeMismatch;
    }
};
