const std = @import("std");
const pango = @import("../pango.zig");
const safety = @import("safety");
const c = pango.c;

pub const Layout = opaque {
    /// Create a new `pango.Layout` object with attributes initialized to
    /// default values for a particular PangoContext.
    ///
    /// **Parameters**
    ///
    /// - `context`: a `pango.Context`.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.Layout`.
    ///
    /// **NOTE**: The caller owns the created layout and should call
    /// `layout.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const layout = try pango.Layout.create(pango_context);
    /// defer layout.destroy();
    /// ```
    ///
    pub fn create(context: *pango.Context) !*Layout {
        const layout = c.pango_layout_new(context) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), layout);
        return layout;
    }

    pub fn copy(self: *Layout) !*Layout {
        const layout = c.pango_layout_copy(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), layout);
        return layout;
    }

    pub fn setAttributes(self: *Layout, attrs: *pango.AttrList) void {
        c.pango_layout_set_attributes(self, attrs);
    }

    pub fn getAttributes(self: *Layout) !*pango.AttrList {
        return c.pango_layout_get_attributes(self) orelse error.NullPointer;
    }

    pub fn getContext(self: *Layout) !*pango.Context {
        return c.pango_layout_get_context(self) orelse return error.NullPointer;
    }

    // pub fn setAttributes
    // pub fn getAttributes

    /// Sets the text of the layout.
    ///
    /// This function validates `text` and renders invalid UTF-8 with a
    /// placeholder glyph.
    ///
    /// Note that if you have used `pango.Layout.setMarkup()` or
    /// `pango.Layout.setMarkupWithAccel()` on layout before, you may want to
    /// call `pango.Layout.setAttributes()` to clear the attributes set on the
    /// layout from the markup as this function does not clear attributes.
    ///
    /// **Parameters**
    /// - `text`: the text as a `const u8` slice.
    pub fn setText(self: *Layout, text: []const u8) void {
        c.pango_layout_set_text(self, text.ptr, @intCast(text.len));
    }

    /// Gets the text in the layout.
    ///
    /// The returned text should not be freed or modified.
    pub fn getText(self: *Layout) []const u8 {
        return std.mem.span(c.pango_layout_get_text(self));
    }

    /// Returns the number of Unicode characters in the the text of `self`.
    pub fn getCharacterCount(self: *Layout) u32 {
        return @intCast(c.pango_layout_get_character_count(self));
    }

    /// Sets the layout text and attribute list from marked-up text.
    ///
    /// See [Pango Markup](https://docs.gtk.org/Pango/pango_markup.html).
    ///
    /// Replaces the current text and attribute list.
    ///
    /// This is the same as `pango.Layout.setMarkupWithAccel()`, but the markup
    /// text isn’t scanned for accelerators.
    ///
    /// **Parameters**
    /// - `markup`: marked-up text
    pub fn setMarkup(self: *Layout, markup: []const u8) void {
        c.pango_layout_set_markup(self, markup.ptr, @intCast(markup.len));
    }

    /// Sets the layout text and attribute list from marked-up text.
    ///
    /// See [Pango Markup](https://docs.gtk.org/Pango/pango_markup.html).
    ///
    /// Replaces the current text and attribute list.
    ///
    /// If accel_marker is nonzero, the given character will mark the character
    /// following it as an accelerator. For example, accel_marker might be an
    /// ampersand or underscore. All characters marked as an accelerator will
    /// receive a `pango.Underline.Low` attribute, and the first character so
    /// marked will be returned in accel_char. Two accel_marker characters
    /// following each other produce a single literal accel_marker character.
    ///
    /// **Parameters**
    /// - `markup`: marked-up text
    /// - `accel_marker`: marker for accelerators in the text
    /// - `accel_char`: return location for first located accelerator
    pub fn setMarkupWithAccel(self: *Layout, markup: []const u8, accel_marker: c_uint, accel_char: *c_uint) void {
        // TODO: look into this, why not return it?
        c.pango_layout_set_markup_with_accel(self, markup.ptr, @intCast(markup.len), accel_marker, accel_char);
    }

    /// Sets the default font description for the layout.
    ///
    /// If no font description is set on the layout, the font description from
    /// the layout’s context is used.
    ///
    /// **Parameters**
    /// - `desc`: the new PangoFontDescription to unset the current font
    /// description
    pub fn setFontDescription(self: *Layout, desc: *const pango.FontDescription) void {
        c.pango_layout_set_font_description(self, desc);
    }

    /// Gets the font description for the layout, if any.
    ///
    /// **Returns**
    ///
    /// a pointer to the layout’s font description, or `null` if the font
    /// description from the layout’s context is inherited.
    ///
    /// **Note**: data is owned by instance.
    pub fn getFontDescription(self: *Layout) ?*const pango.FontDescription {
        return c.pango_layout_get_font_description(self);
    }

    /// Sets the width to which the lines of the `pango.Layout` should wrap or
    /// ellipsized.
    ///
    ///The default value is -1: no width set.
    ///
    /// **Parameters**
    /// - `width`: the desired width in Pango units, or -1 to indicate that no
    /// wrapping or ellipsization should be performed.
    pub fn setWidth(self: *Layout, width: i32) void {
        c.pango_layout_set_width(self, @intCast(width));
    }

    /// Gets the width to which the lines of the `pango.Layout` should wrap.
    ///
    /// **Returns**
    ///
    /// the width in Pango units, or -1 if no width set.
    pub fn getWidth(self: *Layout) i32 {
        return @intCast(c.pango_layout_get_width(self));
    }

    /// Sets the height to which the PangoLayout should be ellipsized at.
    ///
    /// There are two different behaviors, based on whether height is positive
    /// or negative.
    ///
    /// If `height` is positive, it will be the maximum height of the layout.
    /// Only lines would be shown that would fit, and if there is any text
    /// omitted, an ellipsis added. At least one line is included in each
    /// paragraph regardless of how small the height value is. A value of zero
    /// will render exactly one line for the entire layout.
    ///
    /// If `height` is negative, it will be the (negative of) maximum number of
    /// lines per paragraph. That is, the total number of lines shown may well
    /// be more than this value if the layout contains multiple paragraphs of
    /// text. The default value of -1 means that the first line of each
    /// paragraph is ellipsized. This behavior may be changed in the future to
    /// act per layout instead of per paragraph. File a bug against pango at
    /// https://gitlab.gnome.org/gnome/pango if your code relies on this
    /// behavior.
    ///
    /// Height setting only has effect if a positive width is set on layout and
    /// ellipsization mode of layout is not `pango.EllipsizeMode.None`. The
    /// behavior is undefined if a height other than -1 is set and
    /// ellipsization mode is set to `pango.EllipsizeMode.None`, and may change
    /// in the future.
    ///
    /// **Parameters**
    /// - `height`: The desired height of the layout in Pango units if
    /// positive, or desired number of lines if negative.
    pub fn setHeight(self: *Layout, width: i32) void {
        c.pango_layout_set_height(self, @intCast(width));
    }

    /// Gets the height of layout used for ellipsization.
    ///
    /// See `pango.Layout.setHeight()` for details.
    ///
    /// **Returns**
    ///
    /// the height, in Pango units if positive, or number of lines if negative.
    pub fn getHeight(self: *Layout) i32 {
        return @intCast(c.pango_layout_get_height(self));
    }

    /// Sets the wrap mode.
    ///
    /// The wrap mode only has effect if a width is set on the layout with
    /// `pango.Layout.setWidth()`. To turn off wrapping, set the width to -1.
    ///
    /// The default value is `pango.WrapMode.Word`.
    ///
    /// **Parameters**
    /// - `wrap`: wrap mode.
    pub fn setWrap(self: *Layout, wrap: pango.WrapMode) void {
        c.pango_layout_set_wrap(self, wrap);
    }

    /// Gets the wrap mode for the layout.
    ///
    /// Use `pango.Layout.isWrapped()` to query whether any paragraphs were
    /// actually wrapped.
    ///
    /// **Returns**
    ///
    /// active wrap mode.
    pub fn getWrap(self: *Layout) pango.WrapMode {
        return c.pango_layout_get_wrap(self);
    }

    /// Queries whether the layout had to wrap any paragraphs.
    ///
    /// This returns `true` if a positive width is set on layout, ellipsization
    /// mode of layout is set to `.None`, and there are paragraphs exceeding
    /// the layout width that have to be wrapped.
    ///
    /// **Returns**
    /// `true` if any paragraphs had to be wrapped, `false` otherwise.
    pub fn isWrapped(self: *Layout) bool {
        return c.pango_layout_is_wrapped(self) != 0;
    }

    /// Sets the width in Pango units to indent each paragraph.
    ///
    /// A negative value of `indent` will produce a hanging indentation. That
    /// is, the first line will have the full width, and subsequent lines will
    /// be indented by the absolute value of `indent`.
    ///
    /// The indent setting is ignored if layout alignment is set to
    /// `pango.Align.Center`.
    ///
    /// The default value is 0.
    ///
    /// **Parameters**
    /// - `indent`: the amount by which to indent.
    pub fn setIndent(self: *Layout, indent: i32) void {
        c.pango_layout_set_indent(self, @intCast(indent));
    }

    /// Gets the paragraph indent width in Pango units.
    ///
    /// A negative value indicates a hanging indentation.
    ///
    /// **Returns**
    ///
    /// the indent in Pango units.
    pub fn getIndent(self: *Layout) i32 {
        return @intCast(c.pango_layout_get_indent(self));
    }

    /// Sets the amount of spacing in Pango units between the lines
    /// of the layout.
    ///
    /// When placing lines with spacing, Pango arranges things so that
    /// ```
    /// line2.top = line1.bottom + spacing
    /// ```
    /// The default value is 0.
    ///
    /// Note: Since 1.44, Pango is using the line height (as determined by the
    /// font) for placing lines when the line spacing factor is set to a
    /// non-zero value with `pango.Layout.setLineSpacing()`. In that case, the
    /// spacing set with this function is ignored.
    ///
    /// Note: for semantics that are closer to the CSS line-height property,
    /// see pango_attr_line_height_new().
    ///
    /// **Parameters**
    /// - `spacing`: the amount of spacing.
    pub fn setSpacing(self: *Layout, spacing: i32) void {
        // TODO: fix desc
        c.pango_layout_set_spacing(self, @intCast(spacing));
    }

    /// Gets the amount of spacing between the lines of the layout.
    ///
    /// **Returns**
    ///
    /// the spacing in Pango units.
    pub fn getSpacing(self: *Layout) i32 {
        return @intCast(c.pango_layout_get_spacing(self));
    }

    /// Sets a factor for line spacing.
    ///
    /// Typical values are: 0, 1, 1.5, 2. The default values is 0.
    ///
    /// If factor is non-zero, lines are placed so that
    /// ```
    /// baseline2 = baseline1 + factor * height2
    /// ```
    /// where height2 is the line height of the second line (as determined by
    /// the font(s)). In this case, the spacing set with
    /// `pango.Layout.setSpacing()` is ignored.
    ///
    /// If factor is zero (the default), spacing is applied as before.
    ///
    /// Note: for semantics that are closer to the CSS line-height property,
    /// see pango_attr_line_height_new().
    ///
    /// **Parameters**
    /// - `factor`: the new line spacing factor.
    pub fn setLineSpacing(self: *Layout, factor: f32) void {
        // TODO: fix desc
        c.pango_layout_set_line_spacing(self, factor);
    }

    /// Gets the line spacing factor of `self`.
    ///
    /// See `pango.Layout.setLineSpacing()`.
    pub fn getLineSpacing(self: *Layout) f32 {
        return c.pango_layout_get_line_spacing(self);
    }

    /// Sets whether each complete line should be stretched to fill the entire
    /// width of the layout.
    ///
    /// Stretching is typically done by adding whitespace, but for some scripts
    /// (such as Arabic), the justification may be done in more complex ways,
    /// like extending the characters.
    ///
    /// Note that tabs and justification conflict with each other:
    /// Justification will move content away from its tab-aligned positions.
    ///
    /// The default value is `false.
    ///
    /// Also see `pango.Layout.setJustifyLastLine()`.
    ///
    /// **Parameters**:
    /// - `justify`: whether the lines in the layout should be justified.
    pub fn setJustify(self: *Layout, justify: bool) void {
        c.pango_layout_set_justify(self, if (justify) 1 else 0);
    }

    /// Gets whether each complete line should be stretched to fill the entire
    /// width of the layout.
    pub fn getJustify(self: *Layout) bool {
        return c.pango_layout_get_justify(self) != 0;
    }

    /// Sets whether the last line should be stretched to fill the entire width
    /// of the layout.
    ///
    /// This only has an effect if `pango.Layout.setJustify()` has been called
    /// as well.
    ///
    /// The default value is `false`.
    ///
    /// **Parameters**:
    /// - `justify`: whether the last line in the layout should be justified.
    pub fn setJustifyLastLine(self: *Layout, justify: bool) void {
        c.pango_layout_set_justify_last_line(self, if (justify) 1 else 0);
    }

    /// Gets whether the last line should be stretched to fill the entire width
    /// of the layout.
    pub fn getJustifyLastLine(self: *Layout) bool {
        return c.pango_layout_get_justify_last_line(self) != 0;
    }

    /// Sets whether to calculate the base direction for the layout according
    /// to its contents.
    ///
    /// When this flag is on (the default), then paragraphs in layout that
    /// begin with strong right-to-left characters (Arabic and Hebrew
    /// principally), will have right-to-left layout, paragraphs with letters
    /// from other scripts will have left-to-right layout. Paragraphs with only
    /// neutral characters get their direction from the surrounding paragraphs.
    ///
    /// When `false`, the choice between left-to-right and right-to-left layout
    /// is done according to the base direction of the layout’s
    /// `pango.Context`. (See `pango.Context.setBaseDir()`).
    ///
    /// When the auto-computed direction of a paragraph differs from the base
    /// direction of the context, the interpretation of `pango.Align.Left` and
    /// `pango.Align.Right` are swapped.
    ///
    /// **Parameters**:
    /// - `auto_dir`: if TRUE, compute the bidirectional base direction from
    /// the layout’s contents.
    pub fn setAutoDir(self: *Layout, auto_dir: bool) void {
        c.pango_layout_set_auto_dir(self, if (auto_dir) 1 else 0);
    }

    /// Gets whether to calculate the base direction for the layout according
    /// to its contents.
    ///
    /// See `pango.Layout.setAutoDir()`.
    ///
    /// **Returns**
    ///
    /// `true` if the bidirectional base direction is computed from the
    /// layout’s contents, `false` otherwise.
    pub fn getAutoDir(self: *Layout) bool {
        return c.pango_layout_get_auto_dir(self) != 0;
    }

    /// Sets the alignment for the layout: how partial lines are positioned
    /// within the horizontal space available.
    ///
    /// The default alignment is `pango.Align.Left`.
    ///
    /// **Parameters**
    /// - `alignment`: the alignment
    pub fn setAlignment(self: *Layout, alignment: pango.Alignment) void {
        c.pango_layout_set_alignment(self, alignment);
    }

    /// Gets the alignment for the layout: how partial lines are positioned
    /// within the horizontal space available.
    pub fn getAlignment(self: *Layout) pango.Alignment {
        return c.pango_layout_get_alignment(self);
    }

    // pub extern fn pango_layout_set_tabs(layout: ?*pango.Layout, tabs: ?*PangoTabArray) void;
    // pub extern fn pango_layout_get_tabs(layout: ?*pango.Layout) ?*PangoTabArray;

    /// Sets the single paragraph mode of `self`.
    ///
    /// If `setting` is `true`, do not treat newlines and similar characters as
    /// paragraph separators; instead, keep all text in a single paragraph, and
    /// display a glyph for paragraph separator characters. Used when you want
    /// to allow editing of newlines on a single text line.
    ///
    /// The default value is `false`.
    ///
    /// **Parameters**
    /// - `setting`: new setting
    pub fn setSingleParagraphMode(self: *Layout, setting: bool) void {
        c.pango_layout_set_single_paragraph_mode(self, if (setting) 1 else 0);
    }

    /// Obtains whether `self` is in single paragraph mode.
    ///
    /// See `pango.Layout.setSingleParagraphMode()`.
    ///
    /// **Returns**
    ///
    /// `true` if the layout does not break paragraphs at paragraph separator
    /// characters, `false` otherwise.
    pub fn getSingleParagraphMode(self: *Layout) bool {
        return c.pango_layout_get_single_paragraph_mode(self) != 0;
    }

    /// Sets the type of ellipsization being performed for `self`.
    ///
    /// Depending on the ellipsization mode `ellipsize` text is removed from
    /// the start, middle, or end of text so they fit within the width and
    /// height of layout set with `pango.Layout.setWidth()` and
    /// `pango.Layout.setHeight()`.
    ///
    /// If the layout contains characters such as newlines that force it to be
    /// layed out in multiple paragraphs, then whether each paragraph is
    /// ellipsized separately or the entire layout is ellipsized as a whole
    /// depends on the set height of the layout.
    ///
    /// The default value is `pango.EllipsizeMode.None`.
    ///
    /// See `pango.Layout.setHeight()` for details.
    ///
    /// **Parameters**
    /// - `ellipsize`: the new ellipsization mode for `self`.
    pub fn setEllipsize(self: *Layout, ellipsize: pango.EllipsizeMode) void {
        c.pango_layout_set_ellipsize(self, ellipsize);
    }

    /// Gets the type of ellipsization being performed for `self`.
    ///
    /// See `pango.Layout.setEllipsize()`.
    ///
    /// Use `pango.Layout.isEllipsized()` to query whether any paragraphs
    /// were actually ellipsized.
    ///
    /// **Returns**
    ///
    /// the current ellipsization mode for `self`.
    pub fn getEllipsize(self: *Layout) pango.EllipsizeMode {
        return c.pango_layout_get_ellipsize(self);
    }

    /// Queries whether the layout had to ellipsize any paragraphs.
    ///
    /// This returns `true` if the ellipsization mode for layout is not
    /// `pango.EllipsizeMode.None`, a positive width is set on layout, and
    /// there are paragraphs exceeding that width that have to be ellipsized.
    ///
    /// **Returns**
    ///
    /// `true` if any paragraphs had to be ellipsized, `false` otherwise.
    pub fn isEllipsized(self: *Layout) bool {
        return c.pango_layout_is_ellipsized(self) != 0;
    }

    /// Counts the number of unknown glyphs in `self`.
    ///
    /// This function can be used to determine if there are any fonts available
    /// to render all characters in a certain string, or when used in
    /// combination with PANGO_ATTR_FALLBACK, to check if a certain font
    /// supports all the characters in the string.
    ///
    /// **Returns**
    ///
    /// the number of unknown glyphs in `self`.
    pub fn getUnknownGlyphsCount(self: *Layout) u32 {
        // TODO: fix desc
        return @intCast(c.pango_layout_get_unknown_glyphs_count(self));
    }

    /// Gets the text direction at the given character position in `self`.
    ///
    /// **Parameters**
    /// - `index`: the byte index of the char.
    ///
    /// **Returns**
    ///
    /// the text direction at `index`.
    pub fn getDirection(self: *Layout, index: u32) pango.Direction {
        return c.pango_layout_get_direction(self, @intCast(index));
    }

    /// Forces recomputation of any state in the PangoLayout that might depend
    /// on the layout’s context.
    ///
    /// This function should be called if you make changes to the context
    /// subsequent to creating the layout.
    pub fn contextChanged(self: *Layout) void {
        c.pango_layout_context_changed(self);
    }

    /// Returns the current serial number of `self`.
    ///
    /// The serial number is initialized to an small number larger than zero
    /// when a new layout is created and is increased whenever the layout is
    /// changed using any of the setter functions, or the PangoContext it uses
    /// has changed. The serial may wrap, but will never have the value 0.
    /// Since it can wrap, never compare it with “less than”, always use “not
    /// equals”.
    ///
    /// This can be used to automatically detect changes to a `pango.Layout`,
    /// and is useful for example to decide whether a layout needs redrawing.
    /// To force the serial to be increased, use
    /// `pango.Layout.contextChanged()`.
    ///
    /// **Returns**
    ///
    /// the current serial number of `self`.
    pub fn getSerial(self: *Layout) u32 {
        return @intCast(c.pango_layout_get_serial(self));
    }

    /// Increases the reference count of `self`.
    ///
    /// **Returns**
    ///
    /// the same object.
    pub fn reference(self: *Layout) *Layout {
        if (safety.tracing) safety.reference(@returnAddress(), self);
        return @ptrCast(c.g_object_ref(self).?);
    }

    // pub extern fn pango_layout_get_log_attrs(layout: ?*pango.Layout, attrs: [*c]?*PangoLogAttr, n_attrs: [*c]gint) void;
    // pub extern fn pango_layout_get_log_attrs_readonly(layout: ?*pango.Layout, n_attrs: [*c]gint) ?*const PangoLogAttr;
    // pub extern fn pango_layout_index_to_pos(layout: ?*pango.Layout, index_: c_int, pos: [*c]PangoRectangle) void;
    // pub extern fn pango_layout_index_to_line_x(layout: ?*pango.Layout, index_: c_int, trailing: c_bool, line: [*c]c_int, x_pos: [*c]c_int) void;
    // pub extern fn pango_layout_get_cursor_pos(layout: ?*pango.Layout, index_: c_int, strong_pos: [*c]PangoRectangle, weak_pos: [*c]PangoRectangle) void;
    // pub extern fn pango_layout_get_caret_pos(layout: ?*pango.Layout, index_: c_int, strong_pos: [*c]PangoRectangle, weak_pos: [*c]PangoRectangle) void;
    // pub extern fn pango_layout_move_cursor_visually(layout: ?*pango.Layout, strong: c_bool, old_index: c_int, old_trailing: c_int, direction: c_int, new_index: [*c]c_int, new_trailing: [*c]c_int) void;
    // pub extern fn pango_layout_xy_to_index(layout: ?*pango.Layout, x: c_int, y: c_int, index_: [*c]c_int, trailing: [*c]c_int) c_bool;

    /// Computes the logical and ink extents of `self`.
    ///
    /// Logical extents are usually what you want for positioning things. Note
    /// that both extents may have non-zero x and y. You may want to use those
    /// to offset where you render the layout. Not doing that is a very typical
    /// bug that shows up as right-to-left layouts not being correctly
    /// positioned in a layout with a set width.
    ///
    /// The extents are given in layout coordinates and in Pango units; layout
    /// coordinates begin at the top left corner of the layout.
    ///
    /// **Parameters**
    /// - `ink_rect`: rectangle used to store the extents of the layout as
    /// drawn, can be `null`
    /// - `logical_rect`: rectangle used to store the logical extents of the
    /// layout, can be `null`
    pub fn getExtents(self: *Layout, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
        c.pango_layout_get_extents(self, ink_rect, logical_rect);
    }

    /// Computes the logical and ink extents of `self` in device units.
    ///
    /// This function just calls `pango.Layout.getExtents()` followed by two
    /// `pango_extents_to_pixels()` calls, rounding `ink_rect` and
    /// `logical_rect` such that the rounded rectangles fully contain the
    /// unrounded one (that is, passes them as first argument to
    /// `pango_extents_to_pixels()`).
    ///
    /// **Parameters**
    /// - `ink_rect`: rectangle used to store the extents of the layout as
    /// drawn, can be `null`
    /// - `logical_rect`: rectangle used to store the logical extents of the
    /// layout, can be `null`
    pub fn getPixelExtents(self: *Layout, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
        // TODO: fix desc
        c.pango_layout_get_pixel_extents(self, ink_rect, logical_rect);
    }

    /// Determines the logical width and height of a `pango.Layout` in Pango
    /// units.
    ///
    /// This is simply a convenience function around
    /// `pango.Layout.getExtents()`.
    ///
    /// **Parameters**
    /// - `width`: location to store the logical width
    /// - `height`: location to store the logical height
    pub fn getSize(self: *Layout, width: ?*i32, height: ?*i32) void {
        c.pango_layout_get_size(self, @ptrCast(width), @ptrCast(height));
    }

    /// Determines the logical width and height of a `pango.Layout` in device
    /// units.
    ///
    /// `pango.Layout.getSize()` returns the width and height scaled by
    /// `pango.SCALE`. This is simply a convenience function around
    /// `pango.Layout.getPixelExtents()`.
    ///
    /// **Parameters**
    /// - `width`: location to store the logical width
    /// - `height`: location to store the logical height
    pub fn getPixelSize(self: *Layout, width: ?*i32, height: ?*i32) void {
        c.pango_layout_get_pixel_size(self, width, height);
    }

    // pub extern fn pango_layout_get_baseline(layout: ?*pango.Layout) c_int;
    // pub extern fn pango_layout_get_line_count(layout: ?*pango.Layout) c_int;

    pub fn getLine(self: *pango.Layout, line: u32) !*pango.Layout.Line {
        return c.pango_layout_get_line(self, @intCast(line)) orelse error.NullPointer;
    }

    pub fn getLineReadonly(self: *pango.Layout, line: u32) !*pango.Layout.Line {
        return c.pango_layout_get_line_readonly(self, @intCast(line)) orelse error.NullPointer;
    }

    // pub extern fn pango_layout_get_lines(layout: ?*pango.Layout) [*c]GSList;
    // pub extern fn pango_layout_get_lines_readonly(layout: ?*pango.Layout) [*c]GSList;

    /// Decreases the reference count on layout by one. If the result is zero,
    /// then `self` and all associated resources are freed. See
    /// `cairo.Layout.reference()`.
    pub fn destroy(self: *Layout) void {
        if (safety.tracing) safety.destroy(self);
        c.g_object_unref(self);
    }

    pub fn getIter(self: *Layout) !*Iter {
        const iter = c.pango_layout_get_iter(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), iter);
        return iter;
    }

    /// A `pango.Layout.Iter` can be used to iterate over the visual extents of a
    /// `pango.Layout`.
    ///
    /// To obtain a `pango.Layout.Iter`, use `pango.Layout.getIter()`.
    pub const Iter = opaque {
        pub fn copy(self: *Iter) !*Iter {
            const iter = c.pango_layout_iter_copy(self) orelse return error.NullPointer;
            if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), iter);
            return iter;
        }

        pub fn destroy(self: *Iter) void {
            c.pango_layout_iter_free(self);
            if (safety.tracing) safety.destroy(self);
        }

        /// Gets the current byte index.
        ///
        /// Note that iterating forward by char moves in visual order, not
        /// logical order, so indexes may not be sequential. Also, the index
        /// may be equal to the length of the text in the layout, if on the
        /// `null` run (see `pango.Layout.Iter.getRun()`).
        ///
        /// **Returns**
        ///
        /// current byte index.
        pub fn getIndex(self: *Iter) i32 {
            return @intCast(c.pango_layout_iter_get_index(self));
        }

        // pub extern fn pango_layout_iter_get_run(iter: ?*pango.Layout.Iter) [*c]PangoLayoutRun;
        // pub extern fn pango_layout_iter_get_run_readonly(iter: ?*pango.Layout.Iter) [*c]PangoLayoutRun;

        pub fn getLine(self: *Iter) !*pango.Layout.Line {
            return c.pango_layout_iter_get_line(self) orelse error.NullPointer;
        }

        pub fn getLineReadonly(self: *Iter) !*pango.Layout.Line {
            return c.pango_layout_iter_get_line_readonly(self) orelse error.NullPointer;
        }

        pub fn atListLine(self: *Iter) bool {
            return c.pango_layout_iter_at_last_line(self) != 0;
        }

        pub fn getLayout(self: *Iter) !*pango.Layout {
            return c.pango_layout_iter_get_layout(self) orelse error.NullPointer;
        }

        pub fn nextChar(self: *Iter) bool {
            return c.pango_layout_iter_next_char(self) != 0;
        }

        pub fn nextCluster(self: *Iter) bool {
            return c.pango_layout_iter_next_cluster(self) != 0;
        }

        pub fn nextRun(self: *Iter) bool {
            return c.pango_layout_iter_next_run(self) != 0;
        }

        pub fn nextLine(self: *Iter) bool {
            return c.pango_layout_iter_next_line(self) != 0;
        }

        pub fn getCharExtents(self: *Iter) pango.Rectangle {
            var logical_rect: pango.Rectangle = undefined;
            c.pango_layout_iter_get_char_extents(self, &logical_rect);
            return logical_rect;
        }

        pub fn getClusterExtents(self: *Iter, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_iter_get_cluster_extents(self, ink_rect, logical_rect);
        }

        pub fn getRunExtents(self: *Iter, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_iter_get_run_extents(self, ink_rect, logical_rect);
        }

        pub fn getLineExtents(self: *Iter, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_iter_get_line_extents(self, ink_rect, logical_rect);
        }

        pub fn getLineYrange(self: *Iter, y0: *c_int, y1: *c_int) void {
            c.pango_layout_iter_get_line_yrange(self, y0, y1);
        }

        pub fn getLayoutExtents(self: *Iter, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_iter_get_layout_extents(self, ink_rect, logical_rect);
        }

        pub fn getBaseline(self: *Iter) i32 {
            return @intCast(c.pango_layout_iter_get_baseline(self));
        }

        pub fn getRunBaseline(self: *Iter) i32 {
            return @intCast(c.pango_layout_iter_get_run_baseline(self));
        }
    };

    /// A `pango.Layout.Line` represents one of the lines resulting from
    /// laying out a paragraph via `pango.Layout`.
    ///
    /// `pango.Layout.Line` structures are obtained by calling
    /// `pango.Layout.getLine()` and are only valid until the text, attributes,
    /// or settings of the parent `pango.Layout` are modified.
    pub const Line = packed struct {
        // TODO: should we expose that? maybe use opaque?

        /// The layout this line belongs to, might be `null`.
        layout: ?*Layout,
        /// Start of line as byte index into layout.text.
        start_index: c_int,
        /// Length of line in bytes.
        length: c_int,
        /// List of runs in the line, from left to right.
        runs: ?*anyopaque,
        /// `true` if this is the first line of the paragraph.
        is_paragraph_start: bool,
        ///Resolved `pango.Direction` of line.
        resolved_dir: u3,

        /// Increase the reference count of a `pango.Layout.Line` by one.
        ///
        /// **Returns**
        ///
        /// the line passed in.
        pub fn reference(self: *Line) !*Line {
            const ptr = c.pango_layout_line_ref(self) orelse return error.NullPointer;
            if (safety.tracing) safety.reference(@returnAddress(), self);
            return ptr;
        }

        /// Decrease the reference count of a pango.Layout.Line by one.
        ///
        /// If the result is zero, the line and all associated memory will be freed.
        pub fn destroy(self: *Line) void {
            c.pango_layout_line_unref(self);
            if (safety.tracing) safety.destroy(self);
        }

        /// Returns the start index of the line, as byte index into the text of
        /// the layout.
        ///
        /// **Returns**
        ///
        /// the start index of the line.
        pub fn getStartIndex(self: *Line) i32 {
            return @intCast(c.pango_layout_line_get_start_index(self));
        }

        /// Returns the length of the line, in bytes.
        pub fn getLength(self: *Line) i32 {
            return @intCast(c.pango_layout_line_get_length(self));
        }

        /// Returns whether this is the first line of the paragraph.
        pub fn isParagraphStart(self: *Line) bool {
            return c.pango_layout_line_is_paragraph_start(self) != 0;
        }

        /// Returns the resolved direction of the line.
        pub fn getResolvedDirection(self: *Line) pango.Direction {
            return c.pango_layout_line_get_resolved_direction(self);
        }

        /// Converts from x offset to the byte index of the corresponding
        /// character within the text of the layout.
        ///
        /// If `x_pos` is outside the line, `index` and `trailing` will point
        /// to the very first or very last position in the line. This
        /// determination is based on the resolved direction of the paragraph;
        /// for example, if the resolved direction is right-to-left, then an X
        /// position to the right of the line (after it) results in 0 being
        /// stored in `index` and `trailing`. An X position to the left of the
        /// line results in `index` pointing to the (logical) last grapheme in
        /// the line and `trailing` being set to the number of characters in
        /// that grapheme. The reverse is true for a left-to-right line.
        ///
        /// **Parameters**
        /// - `x_pos`: the X offset (in Pango units) from the left edge of the
        /// line
        /// - `index`: location to store calculated byte index for the grapheme
        /// in which the user clicked
        /// - `trailing`: location to store an integer indicating where in the
        /// grapheme the user clicked. It will either be zero, or the number of
        /// characters in the grapheme. 0 represents the leading edge of the
        /// grapheme
        ///
        /// **Returns**
        ///
        /// `false` if `x_pos` was outside the line, `true` if inside.
        pub fn xToIndex(self: *Line, x_pos: c_int, index: *c_int, trailing: *c_int) bool {
            return c.pango_layout_line_x_to_index(self, x_pos, index, trailing) != 0;
        }

        /// Converts an index within a line to a X position.
        ///
        /// **Parameters**
        /// - `index`: byte offset of a grapheme within the layout
        /// - `trailing`: an integer indicating the edge of the grapheme to
        /// retrieve the position of. If > 0, the trailing edge of the
        /// grapheme, if 0, the leading of the grapheme.
        /// - `x_pos`: location to store the x_offset (in Pango units)
        pub fn indexToX(self: *Line, index: c_int, trailing: bool, x_pos: *c_int) void {
            c.pango_layout_line_index_to_x(self, index, if (trailing) 1 else 0, x_pos);
        }

        /// Gets a list of visual ranges corresponding to a given logical
        /// range.
        ///
        /// This list is not necessarily minimal - there may be consecutive
        /// ranges which are adjacent. The ranges will be sorted from left to
        /// right. The ranges are with respect to the left edge of the entire
        /// layout, not with respect to the line.
        ///
        /// **Parameters**
        /// - `start_index`: start byte index of the logical range. If this
        /// value is less than the start index for the line, then the first
        /// range will extend all the way to the leading edge of the layout.
        /// Otherwise, it will start at the leading edge of the first
        /// character.
        /// - `end_index`: ending byte index of the logical range. If this
        /// value is greater than the end index for the line, then the last
        /// range will extend all the way to the trailing edge of the layout.
        /// Otherwise, it will end at the trailing edge of the last character.
        /// - `ranges`: location to store a pointer to an array of ranges. The
        /// array will be of length 2*n_ranges, with each range starting at
        /// (*ranges)[2*n] and of width (*ranges)[2*n + 1] - (*ranges)[2*n].
        /// This array must be freed with `pango.free()`. The coordinates are
        /// relative to the layout and are in Pango units.
        /// - `n_ranges`: the number of ranges stored in ranges
        pub fn getXRanges(line: *Line, start_index: i32, end_index: i32, ranges: [*c][*c]c_int, n_ranges: [*c]c_int) void {
            // TODO: review this
            c.pango_layout_line_get_x_ranges(line, @intCast(start_index), @intCast(end_index), ranges, n_ranges);
        }

        /// Computes the logical and ink extents of a layout line.
        ///
        /// See `pango.Font.getGlyphExtents()` for details about the
        /// interpretation of the rectangles.
        ///
        /// **Parameters**
        /// - `ink_rect`: rectangle used to store the extents of the glyph
        /// string as drawn
        /// - `logical_rect`: rectangle used to store the logical extents of
        /// the glyph string
        pub fn getExtents(self: *pango.Layout.Line, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_line_get_extents(self, ink_rect, logical_rect);
        }

        /// Computes the height of the line, as the maximum of the heights of
        /// fonts used in this line.
        ///
        /// Note that the actual baseline-to-baseline distance between lines of
        /// text is influenced by other factors, such as
        /// `pango.Layout.setSpacing()` and `pango.Layout.setLineSpacing()`.
        pub fn getHeight(self: *Line) i32 {
            var height: c_int = undefined;
            c.pango_layout_line_get_height(self, &height);
            return @intCast(height);
        }

        /// Computes the logical and ink extents of `self` in device units.
        ///
        /// This function just calls `pango.Layout.Line.getExtents()` followed
        /// by two `pango.extentsToPixels()` calls, rounding `ink_rect` and
        /// `logical_rect` such that the rounded rectangles fully contain the
        /// unrounded one (that is, passes them as first argument to
        /// `pango.extentsToPixels()`).
        ///
        /// **Parameters**
        /// - `ink_rect`: rectangle used to store the extents of the glyph
        /// string as drawn
        /// - `logical_rect`: rectangle used to store the logical extents of
        /// the glyph string
        pub fn getPixelExtents(layout_line: *Line, ink_rect: ?*pango.Rectangle, logical_rect: ?*pango.Rectangle) void {
            c.pango_layout_line_get_pixel_extents(layout_line, ink_rect, logical_rect);
        }
    };
};
