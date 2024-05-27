const pango = @import("../pango.zig");

const c_bool = c_int;

// glib
pub extern fn g_free(ptr: ?*anyopaque) void;
pub extern fn g_object_ref(object: ?*anyopaque) ?*anyopaque;
pub extern fn g_object_unref(object: ?*anyopaque) void;

pub extern fn pango_context_new() ?*pango.Context;
pub extern fn pango_context_changed(context: ?*pango.Context) void;
pub extern fn pango_context_set_font_map(context: ?*pango.Context, font_map: ?*pango.FontMap) void;
pub extern fn pango_context_get_font_map(context: ?*pango.Context) ?*pango.FontMap;
pub extern fn pango_context_get_serial(context: ?*pango.Context) c_uint;
// pub extern fn pango_context_list_families(context: ?*pango.Context, families: ***pango.FontFamily, n_families: [*c]c_int) void;
// pub extern fn pango_context_load_font(context: ?*pango.Context, desc: ?*const pango.FontDescription) [*c]PangoFont;
// pub extern fn pango_context_load_fontset(context: ?*pango.Context, desc: ?*const pango.FontDescription, language: ?*PangoLanguage) [*c]PangoFontset;
// pub extern fn pango_context_get_metrics(context: ?*pango.Context, desc: ?*const pango.FontDescription, language: ?*PangoLanguage) [*c]PangoFontMetrics;
pub extern fn pango_context_set_font_description(context: ?*pango.Context, desc: ?*const pango.FontDescription) void;
pub extern fn pango_context_get_font_description(context: ?*pango.Context) ?*pango.FontDescription;
pub extern fn pango_context_get_language(context: ?*pango.Context) ?*pango.Language;
pub extern fn pango_context_set_language(context: ?*pango.Context, language: ?*pango.Language) void;
pub extern fn pango_context_set_base_dir(context: ?*pango.Context, direction: pango.Direction) void;
pub extern fn pango_context_get_base_dir(context: ?*pango.Context) pango.Direction;
pub extern fn pango_context_set_base_gravity(context: ?*pango.Context, gravity: pango.Gravity) void;
pub extern fn pango_context_get_base_gravity(context: ?*pango.Context) pango.Gravity;
pub extern fn pango_context_get_gravity(context: ?*pango.Context) pango.Gravity;
pub extern fn pango_context_set_gravity_hint(context: ?*pango.Context, hint: pango.GravityHint) void;
pub extern fn pango_context_get_gravity_hint(context: ?*pango.Context) pango.GravityHint;
pub extern fn pango_context_set_matrix(context: ?*pango.Context, matrix: [*c]const pango.Matrix) void;
pub extern fn pango_context_get_matrix(context: ?*pango.Context) [*c]const pango.Matrix;
pub extern fn pango_context_set_round_glyph_positions(context: ?*pango.Context, round_positions: c_bool) void;
pub extern fn pango_context_get_round_glyph_positions(context: ?*pango.Context) c_bool;

// layout
pub extern fn pango_layout_new(context: ?*pango.Context) ?*pango.Layout;
pub extern fn pango_layout_copy(src: ?*pango.Layout) ?*pango.Layout;
pub extern fn pango_layout_get_context(layout: ?*pango.Layout) ?*pango.Context;
pub extern fn pango_layout_set_attributes(layout: ?*pango.Layout, attrs: ?*pango.AttrList) void;
pub extern fn pango_layout_get_attributes(layout: ?*pango.Layout) ?*pango.AttrList;
pub extern fn pango_layout_set_text(layout: ?*pango.Layout, text: [*c]const u8, length: c_int) void;
pub extern fn pango_layout_get_text(layout: ?*pango.Layout) [*c]const u8;
pub extern fn pango_layout_get_character_count(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_set_markup(layout: ?*pango.Layout, markup: [*c]const u8, length: c_int) void;
pub extern fn pango_layout_set_markup_with_accel(layout: ?*pango.Layout, markup: [*c]const u8, length: c_int, accel_marker: c_uint, accel_char: [*c]c_uint) void;
pub extern fn pango_layout_set_font_description(layout: ?*pango.Layout, desc: ?*const pango.FontDescription) void;
pub extern fn pango_layout_get_font_description(layout: ?*pango.Layout) ?*const pango.FontDescription;
pub extern fn pango_layout_set_width(layout: ?*pango.Layout, width: c_int) void;
pub extern fn pango_layout_get_width(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_set_height(layout: ?*pango.Layout, height: c_int) void;
pub extern fn pango_layout_get_height(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_set_wrap(layout: ?*pango.Layout, wrap: pango.WrapMode) void;
pub extern fn pango_layout_get_wrap(layout: ?*pango.Layout) pango.WrapMode;
pub extern fn pango_layout_is_wrapped(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_set_indent(layout: ?*pango.Layout, indent: c_int) void;
pub extern fn pango_layout_get_indent(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_set_spacing(layout: ?*pango.Layout, spacing: c_int) void;
pub extern fn pango_layout_get_spacing(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_set_line_spacing(layout: ?*pango.Layout, factor: f32) void;
pub extern fn pango_layout_get_line_spacing(layout: ?*pango.Layout) f32;

pub extern fn pango_layout_set_justify(layout: ?*pango.Layout, justify: c_bool) void;
pub extern fn pango_layout_get_justify(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_set_justify_last_line(layout: ?*pango.Layout, justify: c_bool) void;
pub extern fn pango_layout_get_justify_last_line(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_set_auto_dir(layout: ?*pango.Layout, auto_dir: c_bool) void;
pub extern fn pango_layout_get_auto_dir(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_set_alignment(layout: ?*pango.Layout, alignment: pango.Alignment) void;
pub extern fn pango_layout_get_alignment(layout: ?*pango.Layout) pango.Alignment;
// pub extern fn pango_layout_set_tabs(layout: ?*pango.Layout, tabs: ?*PangoTabArray) void;
// pub extern fn pango_layout_get_tabs(layout: ?*pango.Layout) ?*PangoTabArray;
pub extern fn pango_layout_set_single_paragraph_mode(layout: ?*pango.Layout, setting: c_bool) void;
pub extern fn pango_layout_get_single_paragraph_mode(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_set_ellipsize(layout: ?*pango.Layout, ellipsize: pango.EllipsizeMode) void;
pub extern fn pango_layout_get_ellipsize(layout: ?*pango.Layout) pango.EllipsizeMode;
pub extern fn pango_layout_is_ellipsized(layout: ?*pango.Layout) c_bool;
pub extern fn pango_layout_get_unknown_glyphs_count(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_get_direction(layout: ?*pango.Layout, index: c_int) pango.Direction;
pub extern fn pango_layout_context_changed(layout: ?*pango.Layout) void;
pub extern fn pango_layout_get_serial(layout: ?*pango.Layout) c_uint;
// pub extern fn pango_layout_get_log_attrs(layout: ?*pango.Layout, attrs: [*c]?*PangoLogAttr, n_attrs: [*c]gint) void;
// pub extern fn pango_layout_get_log_attrs_readonly(layout: ?*pango.Layout, n_attrs: [*c]gint) ?*const PangoLogAttr;
// pub extern fn pango_layout_index_to_pos(layout: ?*pango.Layout, index_: c_int, pos: [*c]PangoRectangle) void;
// pub extern fn pango_layout_index_to_line_x(layout: ?*pango.Layout, index_: c_int, trailing: c_bool, line: [*c]c_int, x_pos: [*c]c_int) void;
// pub extern fn pango_layout_get_cursor_pos(layout: ?*pango.Layout, index_: c_int, strong_pos: [*c]PangoRectangle, weak_pos: [*c]PangoRectangle) void;
// pub extern fn pango_layout_get_caret_pos(layout: ?*pango.Layout, index_: c_int, strong_pos: [*c]PangoRectangle, weak_pos: [*c]PangoRectangle) void;
// pub extern fn pango_layout_move_cursor_visually(layout: ?*pango.Layout, strong: c_bool, old_index: c_int, old_trailing: c_int, direction: c_int, new_index: [*c]c_int, new_trailing: [*c]c_int) void;
// pub extern fn pango_layout_xy_to_index(layout: ?*pango.Layout, x: c_int, y: c_int, index_: [*c]c_int, trailing: [*c]c_int) c_bool;
pub extern fn pango_layout_get_extents(layout: ?*pango.Layout, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_get_pixel_extents(layout: ?*pango.Layout, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_get_size(layout: ?*pango.Layout, width: [*c]c_int, height: [*c]c_int) void;
pub extern fn pango_layout_get_pixel_size(layout: ?*pango.Layout, width: [*c]c_int, height: [*c]c_int) void;
// pub extern fn pango_layout_get_baseline(layout: ?*pango.Layout) c_int;
// pub extern fn pango_layout_get_line_count(layout: ?*pango.Layout) c_int;
pub extern fn pango_layout_get_line(layout: ?*pango.Layout, line: c_int) ?*pango.Layout.Line;
pub extern fn pango_layout_get_line_readonly(layout: ?*pango.Layout, line: c_int) ?*pango.Layout.Line;
// pub extern fn pango_layout_get_lines(layout: ?*pango.Layout) [*c]GSList;
// pub extern fn pango_layout_get_lines_readonly(layout: ?*pango.Layout) [*c]GSList;

// FontDescription
pub extern fn pango_font_description_new() ?*pango.FontDescription;
pub extern fn pango_font_description_copy(desc: ?*const pango.FontDescription) ?*pango.FontDescription;
pub extern fn pango_font_description_copy_static(desc: ?*const pango.FontDescription) ?*pango.FontDescription;
pub extern fn pango_font_description_hash(desc: ?*const pango.FontDescription) c_uint;
pub extern fn pango_font_description_equal(desc1: ?*const pango.FontDescription, desc2: ?*const pango.FontDescription) c_bool;
pub extern fn pango_font_description_free(desc: ?*pango.FontDescription) void;
pub extern fn pango_font_descriptions_free(descs: [*c]?*pango.FontDescription, n_descs: c_int) void;
pub extern fn pango_font_description_set_family(desc: ?*pango.FontDescription, family: [*c]const u8) void;
pub extern fn pango_font_description_set_family_static(desc: ?*pango.FontDescription, family: [*c]const u8) void;
pub extern fn pango_font_description_get_family(desc: ?*const pango.FontDescription) [*c]const u8;
pub extern fn pango_font_description_set_style(desc: ?*pango.FontDescription, style: pango.Style) void;
pub extern fn pango_font_description_get_style(desc: ?*const pango.FontDescription) pango.Style;
pub extern fn pango_font_description_set_variant(desc: ?*pango.FontDescription, variant: pango.Variant) void;
pub extern fn pango_font_description_get_variant(desc: ?*const pango.FontDescription) pango.Variant;
pub extern fn pango_font_description_set_weight(desc: ?*pango.FontDescription, weight: pango.Weight) void;
pub extern fn pango_font_description_get_weight(desc: ?*const pango.FontDescription) pango.Weight;
pub extern fn pango_font_description_set_stretch(desc: ?*pango.FontDescription, stretch: pango.Stretch) void;
pub extern fn pango_font_description_get_stretch(desc: ?*const pango.FontDescription) pango.Stretch;
pub extern fn pango_font_description_set_size(desc: ?*pango.FontDescription, size: c_int) void;
pub extern fn pango_font_description_get_size(desc: ?*const pango.FontDescription) c_int;
pub extern fn pango_font_description_set_absolute_size(desc: ?*pango.FontDescription, size: f64) void;
pub extern fn pango_font_description_get_size_is_absolute(desc: ?*const pango.FontDescription) c_bool;
pub extern fn pango_font_description_set_gravity(desc: ?*pango.FontDescription, gravity: pango.Gravity) void;
pub extern fn pango_font_description_get_gravity(desc: ?*const pango.FontDescription) pango.Gravity;
pub extern fn pango_font_description_set_variations_static(desc: ?*pango.FontDescription, variations: [*c]const u8) void;
pub extern fn pango_font_description_set_variations(desc: ?*pango.FontDescription, variations: [*c]const u8) void;
pub extern fn pango_font_description_get_variations(desc: ?*const pango.FontDescription) [*c]const u8;
pub extern fn pango_font_description_get_set_fields(desc: ?*const pango.FontDescription) pango.FontMask;
pub extern fn pango_font_description_unset_fields(desc: ?*pango.FontDescription, to_unset: pango.FontMask) void;
pub extern fn pango_font_description_merge(desc: ?*pango.FontDescription, desc_to_merge: ?*const pango.FontDescription, replace_existing: c_bool) void;
pub extern fn pango_font_description_merge_static(desc: ?*pango.FontDescription, desc_to_merge: ?*const pango.FontDescription, replace_existing: c_bool) void;
pub extern fn pango_font_description_better_match(desc: ?*const pango.FontDescription, old_match: ?*const pango.FontDescription, new_match: ?*const pango.FontDescription) c_bool;
pub extern fn pango_font_description_from_string(str: [*c]const u8) ?*pango.FontDescription;
pub extern fn pango_font_description_to_string(desc: ?*const pango.FontDescription) [*c]u8;
pub extern fn pango_font_description_to_filename(desc: ?*const pango.FontDescription) [*c]u8;

// LayoutIter
pub extern fn pango_layout_get_iter(layout: ?*pango.Layout) ?*pango.Layout.Iter;
pub extern fn pango_layout_iter_copy(iter: ?*pango.Layout.Iter) ?*pango.Layout.Iter;
pub extern fn pango_layout_iter_free(iter: ?*pango.Layout.Iter) void;
pub extern fn pango_layout_iter_get_index(iter: ?*pango.Layout.Iter) c_int;
// pub extern fn pango_layout_iter_get_run(iter: ?*pango.Layout.Iter) [*c]PangoLayoutRun;
// pub extern fn pango_layout_iter_get_run_readonly(iter: ?*pango.Layout.Iter) [*c]PangoLayoutRun;
pub extern fn pango_layout_iter_get_line(iter: ?*pango.Layout.Iter) ?*pango.Layout.Line;
pub extern fn pango_layout_iter_get_line_readonly(iter: ?*pango.Layout.Iter) ?*pango.Layout.Line;
pub extern fn pango_layout_iter_at_last_line(iter: ?*pango.Layout.Iter) c_bool;
pub extern fn pango_layout_iter_get_layout(iter: ?*pango.Layout.Iter) ?*pango.Layout;
pub extern fn pango_layout_iter_next_char(iter: ?*pango.Layout.Iter) c_bool;
pub extern fn pango_layout_iter_next_cluster(iter: ?*pango.Layout.Iter) c_bool;
pub extern fn pango_layout_iter_next_run(iter: ?*pango.Layout.Iter) c_bool;
pub extern fn pango_layout_iter_next_line(iter: ?*pango.Layout.Iter) c_bool;
pub extern fn pango_layout_iter_get_char_extents(iter: ?*pango.Layout.Iter, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_iter_get_cluster_extents(iter: ?*pango.Layout.Iter, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_iter_get_run_extents(iter: ?*pango.Layout.Iter, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_iter_get_line_extents(iter: ?*pango.Layout.Iter, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_iter_get_line_yrange(iter: ?*pango.Layout.Iter, y0_: [*c]c_int, y1_: [*c]c_int) void;
pub extern fn pango_layout_iter_get_layout_extents(iter: ?*pango.Layout.Iter, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_iter_get_baseline(iter: ?*pango.Layout.Iter) c_int;
pub extern fn pango_layout_iter_get_run_baseline(iter: ?*pango.Layout.Iter) c_int;

// LayoutLine
pub extern fn pango_layout_line_ref(line: ?*pango.Layout.Line) ?*pango.Layout.Line;
pub extern fn pango_layout_line_unref(line: ?*pango.Layout.Line) void;
pub extern fn pango_layout_line_get_start_index(line: ?*pango.Layout.Line) c_int;
pub extern fn pango_layout_line_get_length(line: ?*pango.Layout.Line) c_int;
pub extern fn pango_layout_line_is_paragraph_start(line: ?*pango.Layout.Line) c_bool;
pub extern fn pango_layout_line_get_resolved_direction(line: ?*pango.Layout.Line) pango.Direction;
pub extern fn pango_layout_line_x_to_index(line: ?*pango.Layout.Line, x_pos: c_int, index_: [*c]c_int, trailing: [*c]c_int) c_bool;
pub extern fn pango_layout_line_index_to_x(line: ?*pango.Layout.Line, index_: c_int, trailing: c_bool, x_pos: [*c]c_int) void;
pub extern fn pango_layout_line_get_x_ranges(line: ?*pango.Layout.Line, start_index: c_int, end_index: c_int, ranges: [*c][*c]c_int, n_ranges: [*c]c_int) void;
pub extern fn pango_layout_line_get_extents(line: ?*pango.Layout.Line, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;
pub extern fn pango_layout_line_get_height(line: ?*pango.Layout.Line, height: [*c]c_int) void;
pub extern fn pango_layout_line_get_pixel_extents(layout_line: ?*pango.Layout.Line, ink_rect: [*c]pango.Rectangle, logical_rect: [*c]pango.Rectangle) void;

// Language
pub extern fn pango_language_get_default() ?*pango.Language;
pub extern fn pango_language_get_preferred() [*c]?*pango.Language;
pub extern fn pango_language_from_string(language: [*c]const u8) ?*pango.Language;
pub extern fn pango_language_to_string(language: ?*pango.Language) [*c]const u8;
pub extern fn pango_language_get_sample_string(language: ?*pango.Language) [*c]const u8;
pub extern fn pango_language_matches(language: ?*pango.Language, range_list: [*c]const u8) c_bool;
// pub extern fn pango_language_includes_script(language: ?*pango.Language, script: pango.Script) gboolean;
// pub extern fn pango_language_get_scripts(language: ?*pango.Language, num_scripts: [*c]c_int) [*c]const pango.Script;

// Matrix
pub extern fn pango_matrix_copy(matrix: [*c]const pango.Matrix) [*c]pango.Matrix;
pub extern fn pango_matrix_free(matrix: [*c]pango.Matrix) void;
pub extern fn pango_matrix_translate(matrix: [*c]pango.Matrix, tx: f64, ty: f64) void;
pub extern fn pango_matrix_scale(matrix: [*c]pango.Matrix, scale_x: f64, scale_y: f64) void;
pub extern fn pango_matrix_rotate(matrix: [*c]pango.Matrix, degrees: f64) void;
pub extern fn pango_matrix_concat(matrix: [*c]pango.Matrix, new_matrix: [*c]const pango.Matrix) void;
pub extern fn pango_matrix_transform_point(matrix: [*c]const pango.Matrix, x: [*c]f64, y: [*c]f64) void;
pub extern fn pango_matrix_transform_distance(matrix: [*c]const pango.Matrix, dx: [*c]f64, dy: [*c]f64) void;
pub extern fn pango_matrix_transform_rectangle(matrix: [*c]const pango.Matrix, rect: [*c]pango.Rectangle) void;
pub extern fn pango_matrix_transform_pixel_rectangle(matrix: [*c]const pango.Matrix, rect: [*c]pango.Rectangle) void;
pub extern fn pango_matrix_get_font_scale_factor(matrix: [*c]const pango.Matrix) f64;
pub extern fn pango_matrix_get_font_scale_factors(matrix: [*c]const pango.Matrix, xscale: [*c]f64, yscale: [*c]f64) void;
pub extern fn pango_matrix_get_slant_ratio(matrix: [*c]const pango.Matrix) f64;

// Attribute
// pub extern fn pango_attr_type_register(name: [*c]const u8) PangoAttrType;
// pub extern fn pango_attr_type_get_name(@"type": PangoAttrType) [*c]const u8;
// pub extern fn pango_attribute_init(attr: [*c]PangoAttribute, klass: [*c]const PangoAttrClass) void;
// pub extern fn pango_attribute_copy(attr: [*c]const PangoAttribute) [*c]PangoAttribute;
pub extern fn pango_attribute_destroy(attr: [*c]pango.Attribute) void;
// pub extern fn pango_attribute_equal(attr1: [*c]const PangoAttribute, attr2: [*c]const PangoAttribute) gboolean;

// AttrList
pub extern fn pango_attr_list_new() ?*pango.AttrList;
pub extern fn pango_attr_list_ref(list: ?*pango.AttrList) ?*pango.AttrList;
pub extern fn pango_attr_list_unref(list: ?*pango.AttrList) void;
pub extern fn pango_attr_list_copy(list: ?*pango.AttrList) ?*pango.AttrList;
pub extern fn pango_attr_list_insert(list: ?*pango.AttrList, attr: [*c]pango.Attribute) void;
pub extern fn pango_attr_list_insert_before(list: ?*pango.AttrList, attr: [*c]pango.Attribute) void;
pub extern fn pango_attr_list_change(list: ?*pango.AttrList, attr: [*c]pango.Attribute) void;
pub extern fn pango_attr_list_splice(list: ?*pango.AttrList, other: ?*pango.AttrList, pos: c_int, len: c_int) void;
pub extern fn pango_attr_list_update(list: ?*pango.AttrList, pos: c_int, remove: c_int, add: c_int) void;
pub extern fn pango_attr_list_filter(list: ?*pango.AttrList, func: pango.AttrFilterFunc, data: ?*anyopaque) ?*pango.AttrList;
// pub extern fn pango_attr_list_get_attributes(list: ?*pango.AttrList) [*c]GSList;
pub extern fn pango_attr_list_equal(list: ?*pango.AttrList, other_list: ?*pango.AttrList) c_bool;
pub extern fn pango_attr_list_to_string(list: ?*pango.AttrList) [*c]u8;
pub extern fn pango_attr_list_from_string(text: [*c]const u8) ?*pango.AttrList;

// AttrShape
pub extern fn pango_attr_shape_new(ink_rect: [*c]const pango.Rectangle, logical_rect: [*c]const pango.Rectangle) [*c]pango.Attribute;
pub extern fn pango_attr_shape_new_with_data(ink_rect: [*c]const pango.Rectangle, logical_rect: [*c]const pango.Rectangle, data: ?*anyopaque, copy_func: pango.AttrDataCopyFunc, destroy_func: pango.GDestroyNotify) [*c]pango.Attribute;
