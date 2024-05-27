const cairo = @import("cairo");
const pango = @import("pango");
const pangocairo = @import("../pangocairo.zig");

pub extern fn pango_cairo_font_get_scaled_font(font: ?*pangocairo.Font) ?*cairo.ScaledFont;

pub extern fn pango_cairo_font_map_new() ?*pangocairo.FontMap;
pub extern fn pango_cairo_font_map_new_for_font_type(font_type: cairo.FontFace.Type) ?*pangocairo.FontMap;
pub extern fn pango_cairo_font_map_get_default() ?*pangocairo.FontMap;
pub extern fn pango_cairo_font_map_set_default(font_map: ?*pangocairo.FontMap) void;
pub extern fn pango_cairo_font_map_get_font_type(font_map: ?*pangocairo.FontMap) cairo.FontFace.Type;
pub extern fn pango_cairo_font_map_set_resolution(font_map: ?*pangocairo.FontMap, dpi: f64) void;
pub extern fn pango_cairo_font_map_get_resolution(font_map: ?*pangocairo.FontMap) f64;
pub extern fn pango_cairo_font_map_create_context(font_map: ?*pangocairo.FontMap) ?*pango.Context;

pub extern fn pango_cairo_create_context(cr: ?*cairo.Context) ?*pango.Context;
pub extern fn pango_cairo_update_context(cr: ?*cairo.Context, context: ?*pango.Context) void;
pub extern fn pango_cairo_create_layout(cr: ?*cairo.Context) ?*pango.Layout;
pub extern fn pango_cairo_update_layout(cr: ?*cairo.Context, layout: ?*pango.Layout) void;
// pub extern fn pango_cairo_show_glyph_string(cr: ?*cairo.Context, font: [*c]PangoFont, glyphs: [*c]PangoGlyphString) void;
// pub extern fn pango_cairo_show_glyph_item(cr: ?*cairo.Context, text: [*c]const u8, glyph_item: [*c]PangoGlyphItem) void;
pub extern fn pango_cairo_show_layout_line(cr: ?*cairo.Context, line: ?*pango.Layout.Line) void;
pub extern fn pango_cairo_show_layout(cr: ?*cairo.Context, layout: ?*pango.Layout) void;
pub extern fn pango_cairo_show_error_underline(cr: ?*cairo.Context, x: f64, y: f64, width: f64, height: f64) void;
// pub extern fn pango_cairo_glyph_string_path(cr: ?*cairo.Context, font: [*c]PangoFont, glyphs: [*c]PangoGlyphString) void;
pub extern fn pango_cairo_layout_path(cr: ?*cairo.Context, layout: ?*pango.Layout) void;
pub extern fn pango_cairo_layout_line_path(cr: ?*cairo.Context, line: ?*pango.Layout.Line) void;
pub extern fn pango_cairo_error_underline_path(cr: ?*cairo.Context, x: f64, y: f64, width: f64, height: f64) void;

pub extern fn pango_cairo_context_set_font_options(context: ?*pango.Context, options: ?*const cairo.FontOptions) void;
pub extern fn pango_cairo_context_get_font_options(context: ?*pango.Context) ?*const cairo.FontOptions;
pub extern fn pango_cairo_context_set_resolution(context: ?*pango.Context, dpi: f64) void;
pub extern fn pango_cairo_context_get_resolution(context: ?*pango.Context) f64;
pub extern fn pango_cairo_context_set_shape_renderer(context: ?*pango.Context, func: pangocairo.ShapeRendererFunc, data: ?*anyopaque, dnotify: pango.GDestroyNotify) void;
pub extern fn pango_cairo_context_get_shape_renderer(context: ?*pango.Context, data: [*c]?*anyopaque) pangocairo.ShapeRendererFunc;
