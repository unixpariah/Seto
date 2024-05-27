const pango = @import("pango");
const cairo = @import("cairo");
const pangocairo = @import("../pangocairo.zig");
const c = pangocairo.c;

/// `pangocairo.Font` is an interface exported by fonts for use with Cairo.
///
/// The actual type of the font will depend on the particular font technology
/// Cairo was compiled to use.
pub const Font = opaque {
    /// Gets the `cairo.ScaledFont` used by font.
    ///
    /// **Returns**
    ///
    /// the `cairo.ScaledFont` used by font. The scaled font can be referenced
    /// and kept using `cairo.ScaledFont.reference()`.
    pub fn getScaledFont(self: *Font) !*cairo.ScaledFont {
        return c.pango_cairo_font_get_scaled_font(self) orelse error.NullPointer;
    }
};

pub const FontMap = opaque {
    pub fn new() !*FontMap {
        return c.pango_cairo_font_map_new() orelse error.NullPointer;
    }

    pub fn newForFontType(font_type: cairo.FontFace.Type) !*FontMap {
        return c.pango_cairo_font_map_new_for_font_type(font_type) orelse error.NullPointer;
    }

    pub fn getDefault() !*FontMap {
        return c.pango_cairo_font_map_get_default() orelse error.NullPointer;
    }

    pub fn setDefault(self: ?*FontMap) void {
        c.pango_cairo_font_map_set_default(self);
    }

    pub fn getFontType(self: *FontMap) void {
        return c.pango_cairo_font_map_get_font_type(self);
    }

    pub fn setResolution(self: *FontMap, dpi: f64) void {
        c.pango_cairo_font_map_set_resolution(self, dpi);
    }

    pub fn getResolution(self: *FontMap) f64 {
        return c.pango_cairo_font_map_get_resolution(self);
    }

    pub fn createContext(self: *FontMap) !*pango.Context {
        return c.pango_cairo_font_map_create_context(self) orelse error.NullPointer;
    }
};
