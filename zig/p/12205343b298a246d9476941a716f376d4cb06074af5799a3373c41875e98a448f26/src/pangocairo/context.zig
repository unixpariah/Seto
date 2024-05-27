const cairo = @import("cairo");
const pango = @import("pango");
const pangocairo = @import("../pangocairo.zig");
const c = pangocairo.c;
const safety = @import("safety");

/// Creates a context object set up to match the current transformation and
/// target surface of the Cairo context.
///
/// This context can then be used to create a layout using
/// `pango.Layout.create()`.
///
/// This function is a convenience function that creates a context using the
/// default font map, then updates it to `self`. If you just need to create a
/// layout for use with `cr` and do not need to access `pango.Context`
/// directly, you can use `cairo.Context.createLayout()` instead.
///
/// **Returns**
///
/// the newly created `pango.Context`.
///
/// **NOTE**: The caller owns the created context and should call
/// `pango.Context.destroy()` when done with it. You can use idiomatic Zig
/// pattern with `defer`:
/// ```zig
/// const pg_ctx = try cairo_ctx.createPangoContext();
/// defer pg_ctx.destroy();
/// ```
pub fn createPangoContext(self: *cairo.Context) cairo.CairoError!*pango.Context {
    const context = c.pango_cairo_create_context(self) orelse return error.NullPointer;
    if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), context);
    return context;
}

/// Updates a `pango.Context` previously created for use with Cairo to match
/// the current transformation and target surface of a Cairo context.
///
/// If any layouts have been created for the context, it’s necessary to call
/// `.contextChanged()` on those layouts.
///
/// **Parameters**
/// - `context`: a `pango.Context`, from a pangocairo font map.
pub fn updatePangoContext(self: *cairo.Context, context: *pango.Context) void {
    c.pango_cairo_update_context(self, context);
}

/// Creates a layout object set up to match the current transformation and
/// target surface of the Cairo context.
///
/// This layout can then be used for text measurement with functions like
/// `pango.Layout.getSize()` or drawing with functions like
/// `cairo.Context.showLayout()`. If you change the transformation or target
/// surface for `self`, you need to call `cairo.Context.updateLayout()`.
///
/// **Returns**
///
/// the newly created `pango.Layout`.
///
/// **NOTE**: The caller owns the created layout and should call
/// `layout.destroy()` when done with it. You can use idiomatic Zig pattern
/// with `defer`:
/// ```zig
/// const layout = try cairo_ctx.createLayout();
/// defer layout.destroy();
/// ```
pub fn createLayout(self: *cairo.Context) cairo.CairoError!*pango.Layout {
    const layout = c.pango_cairo_create_layout(self) orelse return error.NullPointer;
    if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), layout);
    return layout;
}

/// Updates the private `pango.Context` of a `pango.Layout` created with
/// `cairo.Context.createLayout()` to match the current transformation and
/// target surface of a Cairo context.
///
/// **Parameters**
/// - `layout`: A `pango.Layout`, from `cairo.Context.createLayout()`.
pub fn updateLayout(self: *cairo.Context, layout: *pango.Layout) void {
    c.pango_cairo_update_layout(self, layout);
}

// pub extern fn pango_cairo_show_glyph_string(cr: ?*cairo.Context, font: [*c]PangoFont, glyphs: [*c]PangoGlyphString) void;
// pub extern fn pango_cairo_show_glyph_item(cr: ?*cairo.Context, text: [*c]const u8, glyph_item: [*c]PangoGlyphItem) void;

pub fn showLayoutLine(self: *cairo.Context, line: *pango.Layout.Line) void {
    c.pango_cairo_show_layout_line(self, line);
}

pub fn showLayout(self: *cairo.Context, layout: *pango.Layout) void {
    c.pango_cairo_show_layout(self, layout);
}

pub fn showErrorUnderline(self: *cairo.Context, x: f64, y: f64, width: f64, height: f64) void {
    c.pango_cairo_show_error_underline(self, x, y, width, height);
}

// pub extern fn pango_cairo_glyph_string_path(cr: ?*cairo.Context, font: [*c]PangoFont, glyphs: [*c]PangoGlyphString) void;

/// Adds the text in a `pango.Layout` to the current path in the specified
/// cairo context.
///
/// The top-left corner of the PangoLayout will be at the current point of the
/// cairo context.
pub fn layoutPath(self: *cairo.Context, line: *pango.Layout) void {
    c.pango_cairo_layout_path(self, line);
}

pub fn layoutLinePath(self: *cairo.Context, line: *pango.Layout.Line) void {
    c.pango_cairo_layout_line_path(self, line);
}

pub fn layoutLine(self: *cairo.Context, layout: *pango.Layout) void {
    c.pango_cairo_layout_path(self, layout);
}

pub fn errorUnderlinePath(self: *cairo.Context, x: f64, y: f64, width: f64, height: f64) void {
    c.pango_cairo_error_underline_path(self, x, y, width, height);
}
