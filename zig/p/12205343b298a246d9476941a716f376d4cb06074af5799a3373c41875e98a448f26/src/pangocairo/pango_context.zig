const cairo = @import("cairo");
const pango = @import("pango");
const pangocairo = @import("../pangocairo.zig");
const c = pangocairo.c;

/// Sets the font options used when rendering text with this context.
///
/// These options override any options that
/// `cairo.Context.updatePangoContext()` derives from the target surface.
///
/// **Parameters**
/// - `options`: a `cairo.FontOptions`, or `null` to unset any previously set
/// options. A copy is made.
pub fn setFontOptions(self: *pango.Context, options: *const cairo.FontOptions) void {
    c.pango_cairo_context_set_font_options(self, options);
}

/// Retrieves any font rendering options previously set with
/// `pango.Context.setFontOptions()`.
///
/// This function does not report options that are derived from the target
/// surface by `cairo.Context.updatePangoContext()`.
///
/// **Returns**
///
/// the font options previously set on the context, or `null` if no options
/// have been set. This value is owned by the context and must not be modified
/// or freed.
pub fn getFontOptions(self: *pango.Context) !*const cairo.FontOptions {
    return c.pango_cairo_context_get_font_options(self) orelse error.NullPointer;
}

/// Sets the resolution for the context.
///
/// This is a scale factor between points specified in a
/// `pango.FontDescription` and Cairo units. The default value is 96, meaning
/// that a 10 point font will be 13 units high. (10 * 96. / 72. = 13.3).
///
/// **Parameters**
/// - `dpi`: The resolution in “dots per inch”. (Physical inches aren’t
/// actually involved; the terminology is conventional.) A 0 or negative value
/// means to use the resolution from the font map.
pub fn setResolution(self: *pango.Context, dpi: f64) void {
    c.pango_cairo_context_set_resolution(self, dpi);
}

/// Gets the resolution for the context.
///
/// See `pango.Context.setResolution()`.
///
/// **Returns**
///
/// the resolution in “dots per inch”. A negative value will be returned if no
/// resolution has previously been set.
pub fn getResolution(self: *pango.Context) f64 {
    return c.pango_cairo_context_get_resolution(self);
}

/// Sets callback function for context to use for rendering attributes of type
/// `pango.AttrType.Shape`.
///
/// **Parameters**
/// - `func`: callback function for rendering attributes of type
/// `pango.AttrType.Shape`, or `null` to disable shape rendering
/// - `data`: user data that will be passed to `func`
/// - `dnotify`: callback that will be called when the context is freed to
/// release `data`
pub fn setShapeRenderer(self: *pango.Context, func: pangocairo.ShapeRendererFunc, data: ?*anyopaque, dnotify: pango.GDestroyNotify) void {
    c.pango_cairo_context_set_shape_renderer(self, func, data, dnotify);
}

/// Sets callback function for context to use for rendering attributes of type
/// `pango.AttrType.Shape`.
///
/// See `pangocairo.ShapeRendererFunc` for details.
///
/// Retrieves callback function and associated user data for rendering
/// attributes of type `pango.AttrType.Shape` as set by
/// `pango.Context.setShapeRenderer()`, if any.
///
/// **Parameters**
/// - `data`: pointer to `?*anyopaque` to return user data
///
/// **Returns**
///
/// the shape rendering callback previously set on the context, or `null` if no
/// shape rendering callback have been set.
pub fn getShapeRenderer(self: *pango.Context, data: ?*?*anyopaque) pangocairo.ShapeRendererFunc {
    return c.pango_cairo_context_get_shape_renderer(self, data);
}
