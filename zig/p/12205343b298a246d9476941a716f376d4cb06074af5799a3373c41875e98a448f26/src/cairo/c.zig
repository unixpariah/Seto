const cairo = @import("../cairo.zig");

// base Surface
pub extern fn cairo_format_stride_for_width(format: cairo.Surface.Format, width: c_int) c_int;
pub extern fn cairo_surface_create_similar(other: ?*anyopaque, content: cairo.Content, width: c_int, height: c_int) ?*anyopaque;
pub extern fn cairo_surface_create_similar_image(other: ?*anyopaque, format: cairo.Surface.Format, width: c_int, height: c_int) ?*anyopaque;
pub extern fn cairo_surface_create_for_rectangle(target: ?*anyopaque, x: f64, y: f64, width: f64, height: f64) ?*anyopaque;
pub extern fn cairo_surface_reference(surface: ?*anyopaque) ?*anyopaque;
pub extern fn cairo_surface_destroy(surface: ?*anyopaque) void;
pub extern fn cairo_surface_status(surface: ?*anyopaque) cairo.Status;
pub extern fn cairo_surface_finish(surface: ?*anyopaque) void;
pub extern fn cairo_surface_flush(surface: ?*anyopaque) void;
pub extern fn cairo_surface_get_device(surface: ?*anyopaque) ?*cairo.Device;
pub extern fn cairo_surface_get_font_options(surface: ?*anyopaque, options: ?*cairo.FontOptions) void;
pub extern fn cairo_surface_get_content(surface: ?*anyopaque) cairo.Content;
pub extern fn cairo_surface_mark_dirty(surface: ?*anyopaque) void;
pub extern fn cairo_surface_mark_dirty_rectangle(surface: ?*anyopaque, x: c_int, y: c_int, width: c_int, height: c_int) void;
pub extern fn cairo_surface_set_device_offset(surface: ?*anyopaque, x_offset: f64, y_offset: f64) void;
pub extern fn cairo_surface_get_device_offset(surface: ?*anyopaque, x_offset: [*c]f64, y_offset: [*c]f64) void;
pub extern fn cairo_surface_get_device_scale(surface: ?*anyopaque, x_scale: [*c]f64, y_scale: [*c]f64) void;
pub extern fn cairo_surface_set_device_scale(surface: ?*anyopaque, x_scale: f64, y_scale: f64) void;
pub extern fn cairo_surface_set_fallback_resolution(surface: ?*anyopaque, x_pixels_per_inch: f64, y_pixels_per_inch: f64) void;
pub extern fn cairo_surface_get_fallback_resolution(surface: ?*anyopaque, x_pixels_per_inch: [*c]f64, y_pixels_per_inch: [*c]f64) void;
pub extern fn cairo_surface_get_type(surface: ?*anyopaque) cairo.Surface.Type;
pub extern fn cairo_surface_get_reference_count(surface: ?*anyopaque) c_uint;
pub extern fn cairo_surface_set_user_data(surface: ?*anyopaque, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_surface_get_user_data(surface: ?*anyopaque, key: [*c]const cairo.UserDataKey) ?*anyopaque;
pub extern fn cairo_surface_copy_page(surface: ?*anyopaque) void;
pub extern fn cairo_surface_show_page(surface: ?*anyopaque) void;
pub extern fn cairo_surface_has_show_text_glyphs(surface: ?*anyopaque) c_int;
pub extern fn cairo_surface_set_mime_data(surface: ?*anyopaque, mime_type: [*c]const u8, data: [*c]const u8, length: c_ulong, destroy: cairo.DestroyFn, closure: ?*anyopaque) cairo.Status;
pub extern fn cairo_surface_get_mime_data(surface: ?*anyopaque, mime_type: [*c]const u8, data: [*c][*c]const u8, length: [*c]c_ulong) void;
pub extern fn cairo_surface_supports_mime_type(surface: ?*anyopaque, mime_type: [*c]const u8) c_int;
pub extern fn cairo_surface_map_to_image(surface: ?*anyopaque, extents: [*c]const cairo.RectangleInt) ?*cairo.ImageSurface;
pub extern fn cairo_surface_unmap_image(surface: ?*anyopaque, image: ?*cairo.ImageSurface) void;
pub extern fn cairo_surface_write_to_png(surface: ?*anyopaque, filename: [*c]const u8) cairo.Status;
pub extern fn cairo_surface_write_to_png_stream(surface: ?*anyopaque, write_func: cairo.WriteFn, closure: ?*anyopaque) cairo.Status;

// ImageSurface
pub extern fn cairo_image_surface_create(format: cairo.Surface.Format, width: c_int, height: c_int) callconv(.C) ?*cairo.ImageSurface;
pub extern fn cairo_image_surface_create_for_data(data: [*c]u8, format: cairo.Surface.Format, width: c_int, height: c_int, stride: c_int) ?*cairo.ImageSurface;
pub extern fn cairo_image_surface_get_data(surface: ?*cairo.ImageSurface) [*c]u8;
pub extern fn cairo_image_surface_get_format(surface: ?*cairo.ImageSurface) cairo.Surface.Format;
pub extern fn cairo_image_surface_get_width(surface: ?*cairo.ImageSurface) c_int;
pub extern fn cairo_image_surface_get_height(surface: ?*cairo.ImageSurface) c_int;
pub extern fn cairo_image_surface_get_stride(surface: ?*cairo.ImageSurface) c_int;
pub extern fn cairo_image_surface_create_from_png(filename: [*c]const u8) ?*cairo.ImageSurface;
pub extern fn cairo_image_surface_create_from_png_stream(read_func: cairo.ReadFn, closure: ?*const anyopaque) ?*cairo.ImageSurface;

// RecordingSurface
pub extern fn cairo_recording_surface_create(content: cairo.Content, extents: [*c]const cairo.Rectangle) ?*cairo.RecordingSurface;
pub extern fn cairo_recording_surface_ink_extents(surface: ?*cairo.RecordingSurface, x0: [*c]f64, y0: [*c]f64, width: [*c]f64, height: [*c]f64) void;
pub extern fn cairo_recording_surface_get_extents(surface: ?*cairo.RecordingSurface, extents: [*c]cairo.Rectangle) c_int; // bool

// ScriptSurface
pub extern fn cairo_script_create(filename: [*c]const u8) ?*cairo.Script;
pub extern fn cairo_script_create_for_stream(write_func: cairo.WriteFn, closure: ?*anyopaque) ?*cairo.Script;
pub extern fn cairo_script_from_recording_surface(script: ?*cairo.Script, recording_surface: ?*cairo.RecordingSurface) cairo.Status;
pub extern fn cairo_script_set_mode(script: ?*cairo.Script, mode: cairo.Script.Mode) void;
pub extern fn cairo_script_get_mode(script: ?*cairo.Script) cairo.Script.Mode;
pub extern fn cairo_script_surface_create(script: ?*cairo.Script, content: cairo.Content, width: f64, height: f64) ?*cairo.ScriptSurface;
pub extern fn cairo_script_surface_create_for_target(script: ?*cairo.Script, target: ?*cairo.Surface) ?*cairo.ScriptSurface;
pub extern fn cairo_script_write_comment(script: ?*cairo.Script, comment: [*c]const u8, len: c_int) void;

// SvgSurface
pub extern fn cairo_svg_surface_create(filename: [*c]const u8, width_in_points: f64, height_in_points: f64) ?*cairo.SvgSurface;
pub extern fn cairo_svg_surface_create_for_stream(write_func: cairo.WriteFn, closure: ?*const anyopaque, width_in_points: f64, height_in_points: f64) ?*cairo.SvgSurface;
pub extern fn cairo_svg_surface_get_document_unit(surface: ?*cairo.SvgSurface) cairo.SvgSurface.SvgUnit;
pub extern fn cairo_svg_surface_set_document_unit(surface: ?*cairo.SvgSurface, cairo.SvgSurface.SvgUnit) void;
pub extern fn cairo_svg_surface_restrict_to_version(surface: ?*cairo.SvgSurface, version: cairo.SvgSurface.SvgVersion) void;
pub extern fn cairo_svg_get_versions(versions: [*c][*c]const cairo.SvgSurface.SvgVersion, num_versions: [*c]c_int) void;
pub extern fn cairo_svg_version_to_string(version: cairo.SvgSurface.SvgVersion) [*c]const u8;

// PdfSurface
pub extern fn cairo_pdf_surface_create(filename: [*c]const u8, width_in_points: f64, height_in_points: f64) ?*cairo.PdfSurface;
pub extern fn cairo_pdf_surface_create_for_stream(write_func: cairo.WriteFn, closure: ?*anyopaque, width_in_points: f64, height_in_points: f64) ?*cairo.PdfSurface;
pub extern fn cairo_pdf_surface_restrict_to_version(surface: ?*cairo.PdfSurface, version: cairo.PdfSurface.PdfVersion) void;
pub extern fn cairo_pdf_get_versions(versions: [*c][*c]const cairo.PdfSurface.PdfVersion, num_versions: [*c]c_int) void;
pub extern fn cairo_pdf_version_to_string(version: cairo.PdfSurface.PdfVersion) [*c]const u8;
pub extern fn cairo_pdf_surface_set_size(surface: ?*cairo.PdfSurface, width_in_points: f64, height_in_points: f64) void;
pub extern fn cairo_pdf_surface_add_outline(surface: ?*cairo.PdfSurface, parent_id: c_int, utf8: [*c]const u8, link_attribs: [*c]const u8, flags: cairo.PdfSurface.OutlineFlags) c_int;
pub extern fn cairo_pdf_surface_set_metadata(surface: ?*cairo.PdfSurface, metadata: cairo.PdfSurface.Metadata, utf8: [*c]const u8) void;
pub extern fn cairo_pdf_surface_set_page_label(surface: ?*cairo.PdfSurface, utf8: [*c]const u8) void;
pub extern fn cairo_pdf_surface_set_thumbnail_size(surface: ?*cairo.PdfSurface, width: c_int, height: c_int) void;

// Context basic
pub extern fn cairo_rectangle_list_destroy(rectangle_list: [*c]cairo.RectangleList) void;
pub extern fn cairo_create(target: ?*cairo.Surface) ?*cairo.Context;
pub extern fn cairo_reference(cr: ?*cairo.Context) ?*cairo.Context;
pub extern fn cairo_destroy(cr: ?*cairo.Context) void;
pub extern fn cairo_status(cr: ?*cairo.Context) cairo.Status;
pub extern fn cairo_save(cr: ?*cairo.Context) void;
pub extern fn cairo_restore(cr: ?*cairo.Context) void;
pub extern fn cairo_get_target(cr: ?*cairo.Context) ?*cairo.Surface;
pub extern fn cairo_push_group(cr: ?*cairo.Context) void;
pub extern fn cairo_push_group_with_content(cr: ?*cairo.Context, content: cairo.Content) void;
pub extern fn cairo_pop_group(cr: ?*cairo.Context) ?*cairo.SurfacePattern;
pub extern fn cairo_pop_group_to_source(cr: ?*cairo.Context) void;
pub extern fn cairo_get_group_target(cr: ?*cairo.Context) ?*cairo.Surface;
pub extern fn cairo_set_source_rgb(cr: ?*cairo.Context, red: f64, green: f64, blue: f64) void;
pub extern fn cairo_set_source_rgba(cr: ?*cairo.Context, red: f64, green: f64, blue: f64, alpha: f64) void;
pub extern fn cairo_set_source(cr: ?*cairo.Context, source: ?*cairo.Pattern) void;
pub extern fn cairo_set_source_surface(cr: ?*cairo.Context, surface: ?*cairo.Surface, x: f64, y: f64) void;
pub extern fn cairo_get_source(cr: ?*cairo.Context) ?*cairo.Pattern;
pub extern fn cairo_set_antialias(cr: ?*cairo.Context, antialias: cairo.Antialias) void;
pub extern fn cairo_get_antialias(cr: ?*cairo.Context) cairo.Antialias;
pub extern fn cairo_set_dash(cr: ?*cairo.Context, dashes: [*c]const f64, num_dashes: c_int, offset: f64) void;
pub extern fn cairo_get_dash_count(cr: ?*cairo.Context) c_int;
pub extern fn cairo_get_dash(cr: ?*cairo.Context, dashes: [*c]f64, offset: [*c]f64) void;
pub extern fn cairo_set_fill_rule(cr: ?*cairo.Context, fill_rule: cairo.Context.FillRule) void;
pub extern fn cairo_get_fill_rule(cr: ?*cairo.Context) cairo.Context.FillRule;
pub extern fn cairo_set_line_cap(cr: ?*cairo.Context, line_cap: cairo.Context.LineCap) void;
pub extern fn cairo_get_line_cap(cr: ?*cairo.Context) cairo.Context.LineCap;
pub extern fn cairo_set_line_join(cr: ?*cairo.Context, line_join: cairo.Context.LineJoin) void;
pub extern fn cairo_get_line_join(cr: ?*cairo.Context) cairo.Context.LineJoin;
pub extern fn cairo_set_line_width(cr: ?*cairo.Context, width: f64) void;
pub extern fn cairo_get_line_width(cr: ?*cairo.Context) f64;
pub extern fn cairo_set_miter_limit(cr: ?*cairo.Context, limit: f64) void;
pub extern fn cairo_get_miter_limit(cr: ?*cairo.Context) f64;
pub extern fn cairo_set_operator(cr: ?*cairo.Context, op: cairo.Context.Operator) void;
pub extern fn cairo_get_operator(cr: ?*cairo.Context) cairo.Context.Operator;
pub extern fn cairo_set_tolerance(cr: ?*cairo.Context, tolerance: f64) void;
pub extern fn cairo_get_tolerance(cr: ?*cairo.Context) f64;
pub extern fn cairo_clip(cr: ?*cairo.Context) void;
pub extern fn cairo_clip_preserve(cr: ?*cairo.Context) void;
pub extern fn cairo_clip_extents(cr: ?*cairo.Context, x1: [*c]f64, y1: [*c]f64, x2: [*c]f64, y2: [*c]f64) void;
pub extern fn cairo_in_clip(cr: ?*cairo.Context, x: f64, y: f64) c_int;
pub extern fn cairo_reset_clip(cr: ?*cairo.Context) void;
pub extern fn cairo_copy_clip_rectangle_list(cr: ?*cairo.Context) [*c]cairo.RectangleList;
pub extern fn cairo_fill(cr: ?*cairo.Context) void;
pub extern fn cairo_fill_preserve(cr: ?*cairo.Context) void;
pub extern fn cairo_fill_extents(cr: ?*cairo.Context, x1: [*c]f64, y1: [*c]f64, x2: [*c]f64, y2: [*c]f64) void;
pub extern fn cairo_in_fill(cr: ?*cairo.Context, x: f64, y: f64) c_int;
pub extern fn cairo_mask(cr: ?*cairo.Context, pattern: ?*cairo.Pattern) void;
pub extern fn cairo_mask_surface(cr: ?*cairo.Context, surface: ?*cairo.Surface, surface_x: f64, surface_y: f64) void;
pub extern fn cairo_paint(cr: ?*cairo.Context) void;
pub extern fn cairo_paint_with_alpha(cr: ?*cairo.Context, alpha: f64) void;
pub extern fn cairo_stroke(cr: ?*cairo.Context) void;
pub extern fn cairo_stroke_preserve(cr: ?*cairo.Context) void;
pub extern fn cairo_stroke_extents(cr: ?*cairo.Context, x1: [*c]f64, y1: [*c]f64, x2: [*c]f64, y2: [*c]f64) void;
pub extern fn cairo_in_stroke(cr: ?*cairo.Context, x: f64, y: f64) c_int;
pub extern fn cairo_copy_page(cr: ?*cairo.Context) void;
pub extern fn cairo_show_page(cr: ?*cairo.Context) void;
pub extern fn cairo_get_reference_count(cr: ?*cairo.Context) c_uint;
pub extern fn cairo_set_user_data(cr: ?*cairo.Context, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_get_user_data(cr: ?*cairo.Context, key: [*c]const cairo.UserDataKey) ?*anyopaque;

// Context paths
pub extern fn cairo_copy_path(cr: ?*cairo.Context) [*c]cairo.Path;
pub extern fn cairo_copy_path_flat(cr: ?*cairo.Context) [*c]cairo.Path;
pub extern fn cairo_path_destroy(path: [*c]cairo.Path) void;
pub extern fn cairo_append_path(cr: ?*cairo.Context, path: [*c]const cairo.Path) void;
pub extern fn cairo_has_current_point(cr: ?*cairo.Context) c_int; // bool
pub extern fn cairo_get_current_point(cr: ?*cairo.Context, x: [*c]f64, y: [*c]f64) void;
pub extern fn cairo_new_path(cr: ?*cairo.Context) void;
pub extern fn cairo_new_sub_path(cr: ?*cairo.Context) void;
pub extern fn cairo_close_path(cr: ?*cairo.Context) void;
pub extern fn cairo_arc(cr: ?*cairo.Context, xc: f64, yc: f64, radius: f64, angle1: f64, angle2: f64) void;
pub extern fn cairo_arc_negative(cr: ?*cairo.Context, xc: f64, yc: f64, radius: f64, angle1: f64, angle2: f64) void;
pub extern fn cairo_curve_to(cr: ?*cairo.Context, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void;
pub extern fn cairo_line_to(cr: ?*cairo.Context, x: f64, y: f64) void;
pub extern fn cairo_move_to(cr: ?*cairo.Context, x: f64, y: f64) void;
pub extern fn cairo_rectangle(cr: ?*cairo.Context, x: f64, y: f64, width: f64, height: f64) void;
pub extern fn cairo_glyph_path(cr: ?*cairo.Context, glyphs: [*c]const cairo.Glyph, num_glyphs: c_int) void;
pub extern fn cairo_text_path(cr: ?*cairo.Context, utf8: [*c]const u8) void;
pub extern fn cairo_rel_curve_to(cr: ?*cairo.Context, dx1: f64, dy1: f64, dx2: f64, dy2: f64, dx3: f64, dy3: f64) void;
pub extern fn cairo_rel_line_to(cr: ?*cairo.Context, dx: f64, dy: f64) void;
pub extern fn cairo_rel_move_to(cr: ?*cairo.Context, dx: f64, dy: f64) void;
pub extern fn cairo_path_extents(cr: ?*cairo.Context, x1: [*c]f64, y1: [*c]f64, x2: [*c]f64, y2: [*c]f64) void;

// Pattern
pub extern fn cairo_pattern_add_color_stop_rgb(pattern: ?*anyopaque, offset: f64, red: f64, green: f64, blue: f64) void;
pub extern fn cairo_pattern_add_color_stop_rgba(pattern: ?*anyopaque, offset: f64, red: f64, green: f64, blue: f64, alpha: f64) void;
pub extern fn cairo_pattern_get_color_stop_count(pattern: ?*anyopaque, count: [*c]c_int) cairo.Status;
pub extern fn cairo_pattern_get_color_stop_rgba(pattern: ?*anyopaque, index: c_int, offset: [*c]f64, red: [*c]f64, green: [*c]f64, blue: [*c]f64, alpha: [*c]f64) cairo.Status;
pub extern fn cairo_pattern_create_rgb(red: f64, green: f64, blue: f64) ?*cairo.SolidPattern;
pub extern fn cairo_pattern_create_rgba(red: f64, green: f64, blue: f64, alpha: f64) ?*cairo.SolidPattern;
pub extern fn cairo_pattern_get_rgba(pattern: ?*cairo.SolidPattern, red: [*c]f64, green: [*c]f64, blue: [*c]f64, alpha: [*c]f64) cairo.Status;
pub extern fn cairo_pattern_create_for_surface(surface: ?*cairo.Surface) ?*cairo.SurfacePattern;
pub extern fn cairo_pattern_get_surface(pattern: ?*cairo.SurfacePattern, surface: [*c]?*cairo.Surface) cairo.Status;
pub extern fn cairo_pattern_create_linear(x0: f64, y0: f64, x1: f64, y1: f64) ?*cairo.LinearGradientPattern;
pub extern fn cairo_pattern_get_linear_points(pattern: ?*cairo.LinearGradientPattern, x0: [*c]f64, y0: [*c]f64, x1: [*c]f64, y1: [*c]f64) cairo.Status;
pub extern fn cairo_pattern_create_radial(cx0: f64, cy0: f64, radius0: f64, cx1: f64, cy1: f64, radius1: f64) ?*cairo.RadialGradientPattern;
pub extern fn cairo_pattern_get_radial_circles(pattern: ?*cairo.RadialGradientPattern, x0: [*c]f64, y0: [*c]f64, r0: [*c]f64, x1: [*c]f64, y1: [*c]f64, r1: [*c]f64) cairo.Status;
pub extern fn cairo_pattern_create_mesh() ?*cairo.MeshPattern;
pub extern fn cairo_mesh_pattern_begin_patch(pattern: ?*cairo.MeshPattern) void;
pub extern fn cairo_mesh_pattern_end_patch(pattern: ?*cairo.MeshPattern) void;
pub extern fn cairo_mesh_pattern_move_to(pattern: ?*cairo.MeshPattern, x: f64, y: f64) void;
pub extern fn cairo_mesh_pattern_line_to(pattern: ?*cairo.MeshPattern, x: f64, y: f64) void;
pub extern fn cairo_mesh_pattern_curve_to(pattern: ?*cairo.MeshPattern, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void;
pub extern fn cairo_mesh_pattern_set_control_point(pattern: ?*cairo.MeshPattern, point_num: c_uint, x: f64, y: f64) void;
pub extern fn cairo_mesh_pattern_set_corner_color_rgb(pattern: ?*cairo.MeshPattern, corner_num: c_uint, red: f64, green: f64, blue: f64) void;
pub extern fn cairo_mesh_pattern_set_corner_color_rgba(pattern: ?*cairo.MeshPattern, corner_num: c_uint, red: f64, green: f64, blue: f64, alpha: f64) void;
pub extern fn cairo_mesh_pattern_get_patch_count(pattern: ?*cairo.MeshPattern, count: [*c]c_uint) cairo.Status;
pub extern fn cairo_mesh_pattern_get_path(pattern: ?*cairo.MeshPattern, patch_num: c_uint) [*c]cairo.Path;
pub extern fn cairo_mesh_pattern_get_control_point(pattern: ?*cairo.MeshPattern, patch_num: c_uint, point_num: c_uint, x: [*c]f64, y: [*c]f64) cairo.Status;
pub extern fn cairo_mesh_pattern_get_corner_color_rgba(pattern: ?*cairo.MeshPattern, patch_num: c_uint, corner_num: c_uint, red: [*c]f64, green: [*c]f64, blue: [*c]f64, alpha: [*c]f64) cairo.Status;
pub extern fn cairo_pattern_reference(pattern: ?*anyopaque) ?*anyopaque;
pub extern fn cairo_pattern_destroy(pattern: ?*anyopaque) void;
pub extern fn cairo_pattern_status(pattern: ?*anyopaque) cairo.Status;
pub extern fn cairo_pattern_set_extend(pattern: ?*anyopaque, extend: cairo.Pattern.Extend) void;
pub extern fn cairo_pattern_get_extend(pattern: ?*anyopaque) cairo.Pattern.Extend;
pub extern fn cairo_pattern_set_filter(pattern: ?*anyopaque, filter: cairo.Pattern.Filter) void;
pub extern fn cairo_pattern_get_filter(pattern: ?*anyopaque) cairo.Pattern.Filter;
pub extern fn cairo_pattern_set_matrix(pattern: ?*anyopaque, matrix: [*c]const cairo.Matrix) void;
pub extern fn cairo_pattern_get_matrix(pattern: ?*anyopaque, matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_pattern_get_type(pattern: ?*anyopaque) cairo.Pattern.Type;
pub extern fn cairo_pattern_get_reference_count(pattern: ?*anyopaque) c_uint;
pub extern fn cairo_pattern_set_user_data(pattern: ?*anyopaque, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_pattern_get_user_data(pattern: ?*anyopaque, key: [*c]const cairo.UserDataKey) ?*anyopaque;
pub extern fn cairo_pattern_create_raster_source(user_data: ?*anyopaque, content: cairo.Content, width: c_int, height: c_int) ?*cairo.Pattern;
pub extern fn cairo_raster_source_pattern_set_callback_data(pattern: ?*cairo.RasterSourcePattern, data: ?*anyopaque) void;
pub extern fn cairo_raster_source_pattern_get_callback_data(pattern: ?*cairo.RasterSourcePattern) ?*anyopaque;
pub extern fn cairo_raster_source_pattern_set_acquire(pattern: ?*cairo.RasterSourcePattern, acquire: cairo.RasterSourcePattern.AcquireFn, release: cairo.RasterSourcePattern.ReleaseFn) void;
pub extern fn cairo_raster_source_pattern_get_acquire(pattern: ?*cairo.RasterSourcePattern, acquire: [*c]cairo.RasterSourcePattern.AcquireFn, release: [*c]cairo.RasterSourcePattern.ReleaseFn) void;
pub extern fn cairo_raster_source_pattern_set_snapshot(pattern: ?*cairo.RasterSourcePattern, snapshot: cairo.RasterSourcePattern.SnapshotFn) void;
pub extern fn cairo_raster_source_pattern_get_snapshot(pattern: ?*cairo.RasterSourcePattern) cairo.RasterSourcePattern.SnapshotFn;
pub extern fn cairo_raster_source_pattern_set_copy(pattern: ?*cairo.RasterSourcePattern, copy: cairo.RasterSourcePattern.CopyFn) void;
pub extern fn cairo_raster_source_pattern_get_copy(pattern: ?*cairo.RasterSourcePattern) cairo.RasterSourcePattern.CopyFn;
pub extern fn cairo_raster_source_pattern_set_finish(pattern: ?*cairo.RasterSourcePattern, finish: cairo.RasterSourcePattern.FinishFn) void;
pub extern fn cairo_raster_source_pattern_get_finish(pattern: ?*cairo.RasterSourcePattern) cairo.RasterSourcePattern.FinishFn;

// Regions
pub extern fn cairo_region_create() ?*cairo.Region;
pub extern fn cairo_region_create_rectangle(rectangle: [*c]const cairo.RectangleInt) ?*cairo.Region;
pub extern fn cairo_region_create_rectangles(rects: [*c]const cairo.RectangleInt, count: c_int) ?*cairo.Region;
pub extern fn cairo_region_copy(original: ?*const cairo.Region) ?*cairo.Region;
pub extern fn cairo_region_reference(region: ?*cairo.Region) ?*cairo.Region;
pub extern fn cairo_region_destroy(region: ?*cairo.Region) void;
pub extern fn cairo_region_status(region: ?*const cairo.Region) cairo.Status;
pub extern fn cairo_region_get_extents(region: ?*const cairo.Region, extents: [*c]cairo.RectangleInt) void;
pub extern fn cairo_region_num_rectangles(region: ?*const cairo.Region) c_int;
pub extern fn cairo_region_get_rectangle(region: ?*const cairo.Region, nth: c_int, rectangle: [*c]cairo.RectangleInt) void;
pub extern fn cairo_region_is_empty(region: ?*const cairo.Region) c_int; // bool
pub extern fn cairo_region_contains_point(region: ?*const cairo.Region, x: c_int, y: c_int) c_int; // bool
pub extern fn cairo_region_contains_rectangle(region: ?*const cairo.Region, rectangle: [*c]const cairo.RectangleInt) cairo.Region.Overlap;
pub extern fn cairo_region_equal(a: ?*const cairo.Region, b: ?*const cairo.Region) c_int; // bool
pub extern fn cairo_region_translate(region: ?*cairo.Region, dx: c_int, dy: c_int) void;
pub extern fn cairo_region_intersect(dst: ?*cairo.Region, other: ?*const cairo.Region) cairo.Status;
pub extern fn cairo_region_intersect_rectangle(dst: ?*cairo.Region, rectangle: [*c]const cairo.RectangleInt) cairo.Status;
pub extern fn cairo_region_subtract(dst: ?*cairo.Region, other: ?*const cairo.Region) cairo.Status;
pub extern fn cairo_region_subtract_rectangle(dst: ?*cairo.Region, rectangle: [*c]const cairo.RectangleInt) cairo.Status;
pub extern fn cairo_region_union(dst: ?*cairo.Region, other: ?*const cairo.Region) cairo.Status;
pub extern fn cairo_region_union_rectangle(dst: ?*cairo.Region, rectangle: [*c]const cairo.RectangleInt) cairo.Status;
pub extern fn cairo_region_xor(dst: ?*cairo.Region, other: ?*const cairo.Region) cairo.Status;
pub extern fn cairo_region_xor_rectangle(dst: ?*cairo.Region, rectangle: [*c]const cairo.RectangleInt) cairo.Status;

// Tags and Links
pub extern fn cairo_tag_begin(cr: ?*cairo.Context, tag_name: [*c]const u8, attributes: [*c]const u8) void;
pub extern fn cairo_tag_end(cr: ?*cairo.Context, tag_name: [*c]const u8) void;

// Text
pub extern fn cairo_select_font_face(cr: ?*cairo.Context, family: [*c]const u8, slant: cairo.FontFace.FontSlant, weight: cairo.FontFace.FontWeight) void;
pub extern fn cairo_set_font_size(cr: ?*cairo.Context, size: f64) void;
pub extern fn cairo_set_font_matrix(cr: ?*cairo.Context, matrix: [*c]const cairo.Matrix) void;
pub extern fn cairo_get_font_matrix(cr: ?*cairo.Context, matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_set_font_options(cr: ?*cairo.Context, options: ?*const cairo.FontOptions) void;
pub extern fn cairo_get_font_options(cr: ?*cairo.Context, options: ?*cairo.FontOptions) void;
pub extern fn cairo_set_font_face(cr: ?*cairo.Context, font_face: ?*cairo.FontFace) void;
pub extern fn cairo_get_font_face(cr: ?*cairo.Context) ?*cairo.FontFace;
pub extern fn cairo_set_scaled_font(cr: ?*cairo.Context, scaled_font: ?*const cairo.ScaledFont) void;
pub extern fn cairo_get_scaled_font(cr: ?*cairo.Context) ?*cairo.ScaledFont;
pub extern fn cairo_show_text(cr: ?*cairo.Context, utf8: [*c]const u8) void;
pub extern fn cairo_show_glyphs(cr: ?*cairo.Context, glyphs: [*c]const cairo.Glyph, num_glyphs: c_int) void;
pub extern fn cairo_show_text_glyphs(cr: ?*cairo.Context, utf8: [*c]const u8, utf8_len: c_int, glyphs: [*c]const cairo.Glyph, num_glyphs: c_int, clusters: [*c]const cairo.TextCluster, num_clusters: c_int, cluster_flags: cairo.TextCluster.Flags) void;
pub extern fn cairo_font_extents(cr: ?*cairo.Context, extents: [*c]cairo.FontExtents) void;
pub extern fn cairo_text_extents(cr: ?*cairo.Context, utf8: [*c]const u8, extents: [*c]cairo.TextExtents) void;
pub extern fn cairo_glyph_extents(cr: ?*cairo.Context, glyphs: [*c]const cairo.Glyph, num_glyphs: c_int, extents: [*c]cairo.TextExtents) void;
pub extern fn cairo_toy_font_face_create(family: [*c]const u8, slant: cairo.FontFace.FontSlant, weight: cairo.FontFace.FontWeight) ?*cairo.ToyFontFace;
pub extern fn cairo_toy_font_face_get_family(font_face: ?*cairo.ToyFontFace) [*c]const u8;
pub extern fn cairo_toy_font_face_get_slant(font_face: ?*cairo.ToyFontFace) cairo.FontFace.FontSlant;
pub extern fn cairo_toy_font_face_get_weight(font_face: ?*cairo.ToyFontFace) cairo.FontFace.FontWeight;
pub extern fn cairo_glyph_allocate(num_glyphs: c_int) [*c]cairo.Glyph;
pub extern fn cairo_glyph_free(glyphs: [*c]cairo.Glyph) void;
pub extern fn cairo_text_cluster_allocate(num_clusters: c_int) [*c]cairo.TextCluster;
pub extern fn cairo_text_cluster_free(clusters: [*c]cairo.TextCluster) void;

// Transformations
pub extern fn cairo_translate(cr: ?*cairo.Context, tx: f64, ty: f64) void;
pub extern fn cairo_scale(cr: ?*cairo.Context, sx: f64, sy: f64) void;
pub extern fn cairo_rotate(cr: ?*cairo.Context, angle: f64) void;
pub extern fn cairo_transform(cr: ?*cairo.Context, matrix: [*c]const cairo.Matrix) void;
pub extern fn cairo_set_matrix(cr: ?*cairo.Context, matrix: [*c]const cairo.Matrix) void;
pub extern fn cairo_get_matrix(cr: ?*cairo.Context, matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_identity_matrix(cr: ?*cairo.Context) void;
pub extern fn cairo_user_to_device(cr: ?*cairo.Context, x: [*c]f64, y: [*c]f64) void;
pub extern fn cairo_user_to_device_distance(cr: ?*cairo.Context, dx: [*c]f64, dy: [*c]f64) void;
pub extern fn cairo_device_to_user(cr: ?*cairo.Context, x: [*c]f64, y: [*c]f64) void;
pub extern fn cairo_device_to_user_distance(cr: ?*cairo.Context, dx: [*c]f64, dy: [*c]f64) void;

// Device
pub extern fn cairo_device_reference(device: ?*anyopaque) ?*anyopaque;
pub extern fn cairo_device_destroy(device: ?*anyopaque) void;
pub extern fn cairo_device_status(device: ?*anyopaque) cairo.Status;
pub extern fn cairo_device_finish(device: ?*anyopaque) void;
pub extern fn cairo_device_flush(device: ?*anyopaque) void;
pub extern fn cairo_device_get_type(device: ?*anyopaque) cairo.Device.Type;
pub extern fn cairo_device_get_reference_count(device: ?*anyopaque) c_uint;
pub extern fn cairo_device_set_user_data(device: ?*anyopaque, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_device_get_user_data(device: ?*anyopaque, key: [*c]const cairo.UserDataKey) ?*anyopaque;
pub extern fn cairo_device_acquire(device: ?*anyopaque) cairo.Status;
pub extern fn cairo_device_release(device: ?*anyopaque) void;
pub extern fn cairo_device_observer_elapsed(device: ?*cairo.Device) f64;
pub extern fn cairo_device_observer_fill_elapsed(device: ?*cairo.Device) f64;
pub extern fn cairo_device_observer_glyphs_elapsed(device: ?*cairo.Device) f64;
pub extern fn cairo_device_observer_mask_elapsed(device: ?*cairo.Device) f64;
pub extern fn cairo_device_observer_paint_elapsed(device: ?*cairo.Device) f64;
pub extern fn cairo_device_observer_print(device: ?*cairo.Device, write_func: cairo.WriteFn, closure: ?*anyopaque) cairo.Status;
pub extern fn cairo_device_observer_stroke_elapsed(device: ?*cairo.Device) f64;

// Font Face
pub extern fn cairo_font_face_reference(font_face: ?*anyopaque) ?*anyopaque;
pub extern fn cairo_font_face_destroy(font_face: ?*anyopaque) void;
pub extern fn cairo_font_face_status(font_face: ?*anyopaque) cairo.Status;
pub extern fn cairo_font_face_get_type(font_face: ?*anyopaque) cairo.FontFace.Type;
pub extern fn cairo_font_face_get_reference_count(font_face: ?*anyopaque) c_uint;
pub extern fn cairo_font_face_set_user_data(font_face: ?*anyopaque, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_font_face_get_user_data(font_face: ?*anyopaque, key: [*c]const cairo.UserDataKey) ?*anyopaque;

// Font Options
pub extern fn cairo_font_options_create() ?*cairo.FontOptions;
pub extern fn cairo_font_options_copy(original: ?*const cairo.FontOptions) ?*cairo.FontOptions;
pub extern fn cairo_font_options_destroy(options: ?*cairo.FontOptions) void;
pub extern fn cairo_font_options_status(options: ?*cairo.FontOptions) cairo.Status;
pub extern fn cairo_font_options_merge(options: ?*cairo.FontOptions, other: ?*const cairo.FontOptions) void;
pub extern fn cairo_font_options_equal(options: ?*const cairo.FontOptions, other: ?*const cairo.FontOptions) c_int; // bool
pub extern fn cairo_font_options_hash(options: ?*const cairo.FontOptions) c_ulong;
pub extern fn cairo_font_options_set_antialias(options: ?*cairo.FontOptions, antialias: cairo.Antialias) void;
pub extern fn cairo_font_options_get_antialias(options: ?*const cairo.FontOptions) cairo.Antialias;
pub extern fn cairo_font_options_set_subpixel_order(options: ?*cairo.FontOptions, subpixel_order: cairo.SubpixelOrder) void;
pub extern fn cairo_font_options_get_subpixel_order(options: ?*const cairo.FontOptions) cairo.SubpixelOrder;
pub extern fn cairo_font_options_set_hint_style(options: ?*cairo.FontOptions, hint_style: cairo.FontOptions.HintStyle) void;
pub extern fn cairo_font_options_get_hint_style(options: ?*const cairo.FontOptions) cairo.FontOptions.HintStyle;
pub extern fn cairo_font_options_set_hint_metrics(options: ?*cairo.FontOptions, hint_metrics: cairo.FontOptions.HintMetrics) void;
pub extern fn cairo_font_options_get_hint_metrics(options: ?*const cairo.FontOptions) cairo.FontOptions.HintMetrics;
pub extern fn cairo_font_options_set_variations(options: ?*cairo.FontOptions, variations: [*c]const u8) void;
pub extern fn cairo_font_options_get_variations(options: ?*cairo.FontOptions) [*c]const u8;

// Scaled Font
pub extern fn cairo_scaled_font_create(font_face: ?*cairo.FontFace, font_matrix: [*c]const cairo.Matrix, ctm: [*c]const cairo.Matrix, options: ?*const cairo.FontOptions) ?*cairo.ScaledFont;
pub extern fn cairo_scaled_font_reference(scaled_font: ?*cairo.ScaledFont) ?*cairo.ScaledFont;
pub extern fn cairo_scaled_font_destroy(scaled_font: ?*cairo.ScaledFont) void;
pub extern fn cairo_scaled_font_status(scaled_font: ?*cairo.ScaledFont) cairo.Status;
pub extern fn cairo_scaled_font_extents(scaled_font: ?*cairo.ScaledFont, extents: [*c]cairo.FontExtents) void;
pub extern fn cairo_scaled_font_text_extents(scaled_font: ?*cairo.ScaledFont, utf8: [*c]const u8, extents: [*c]cairo.TextExtents) void;
pub extern fn cairo_scaled_font_glyph_extents(scaled_font: ?*cairo.ScaledFont, glyphs: [*c]const cairo.Glyph, num_glyphs: c_int, extents: [*c]cairo.TextExtents) void;
pub extern fn cairo_scaled_font_text_to_glyphs(scaled_font: ?*cairo.ScaledFont, x: f64, y: f64, utf8: [*c]const u8, utf8_len: c_int, glyphs: [*c][*c]cairo.Glyph, num_glyphs: [*c]c_int, clusters: [*c][*c]cairo.TextCluster, num_clusters: [*c]c_int, cluster_flags: [*c]cairo.TextCluster.Flags) cairo.Status;
pub extern fn cairo_scaled_font_get_font_face(scaled_font: ?*cairo.ScaledFont) ?*cairo.FontFace;
pub extern fn cairo_scaled_font_get_font_options(scaled_font: ?*cairo.ScaledFont, options: ?*cairo.FontOptions) void;
pub extern fn cairo_scaled_font_get_font_matrix(scaled_font: ?*cairo.ScaledFont, font_matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_scaled_font_get_ctm(scaled_font: ?*cairo.ScaledFont, ctm: [*c]cairo.Matrix) void;
pub extern fn cairo_scaled_font_get_scale_matrix(scaled_font: ?*cairo.ScaledFont, scale_matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_scaled_font_get_type(scaled_font: ?*cairo.ScaledFont) cairo.FontFace.Type;
pub extern fn cairo_scaled_font_get_reference_count(scaled_font: ?*cairo.ScaledFont) c_uint;
pub extern fn cairo_scaled_font_set_user_data(scaled_font: ?*cairo.ScaledFont, key: [*c]const cairo.UserDataKey, user_data: ?*anyopaque, destroy: cairo.DestroyFn) cairo.Status;
pub extern fn cairo_scaled_font_get_user_data(scaled_font: ?*cairo.ScaledFont, key: [*c]const cairo.UserDataKey) ?*anyopaque;

// Matrix
pub extern fn cairo_matrix_init(matrix: [*c]cairo.Matrix, xx: f64, yx: f64, xy: f64, yy: f64, x0: f64, y0: f64) void;
pub extern fn cairo_matrix_init_identity(matrix: [*c]cairo.Matrix) void;
pub extern fn cairo_matrix_init_translate(matrix: [*c]cairo.Matrix, tx: f64, ty: f64) void;
pub extern fn cairo_matrix_init_scale(matrix: [*c]cairo.Matrix, sx: f64, sy: f64) void;
pub extern fn cairo_matrix_init_rotate(matrix: [*c]cairo.Matrix, radians: f64) void;
pub extern fn cairo_matrix_translate(matrix: [*c]cairo.Matrix, tx: f64, ty: f64) void;
pub extern fn cairo_matrix_scale(matrix: [*c]cairo.Matrix, sx: f64, sy: f64) void;
pub extern fn cairo_matrix_rotate(matrix: [*c]cairo.Matrix, radians: f64) void;
pub extern fn cairo_matrix_invert(matrix: [*c]cairo.Matrix) cairo.Status;
pub extern fn cairo_matrix_multiply(result: [*c]cairo.Matrix, a: [*c]const cairo.Matrix, b: [*c]const cairo.Matrix) void;
pub extern fn cairo_matrix_transform_distance(matrix: [*c]const cairo.Matrix, dx: [*c]f64, dy: [*c]f64) void;
pub extern fn cairo_matrix_transform_point(matrix: [*c]const cairo.Matrix, x: [*c]f64, y: [*c]f64) void;

// Win32
pub extern fn cairo_win32_surface_create(hdc: ?*anyopaque) ?*cairo.Win32Surface;
pub extern fn cairo_win32_surface_create_with_dib(format: cairo.Surface.Format, width: c_int, height: c_int) ?*cairo.Win32Surface;
pub extern fn cairo_win32_surface_create_with_ddb(hdc: ?*anyopaque, format: cairo.Surface.Format, width: c_int, height: c_int) ?*cairo.Win32Surface;
pub extern fn cairo_win32_surface_create_with_format(hdc: ?*anyopaque, format: cairo.Surface.Format) ?*cairo.Win32Surface;
pub extern fn cairo_win32_printing_surface_create(hdc: ?*anyopaque) ?*cairo.Win32Surface;
pub extern fn cairo_win32_surface_get_dc(surface: ?*cairo.Win32Surface) ?*anyopaque;
pub extern fn cairo_win32_surface_get_image(surface: ?*cairo.Win32Surface) ?*cairo.ImageSurface;
