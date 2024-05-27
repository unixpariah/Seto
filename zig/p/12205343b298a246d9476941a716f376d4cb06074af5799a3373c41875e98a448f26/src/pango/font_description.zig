const std = @import("std");
const safety = @import("safety");
const pango = @import("../pango.zig");
const c = pango.c;

/// A `pango.FontDescription` describes a font in an implementation-independent
/// manner.
///
/// `pango.FontDescription` structures are used both to list what fonts are
/// available on the system and also for specifying the characteristics of a
/// font to load.
pub const FontDescription = opaque {
    /// Creates a new font description structure with all fields unset.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.FontDescription`.
    ///
    /// **NOTE**: The caller owns the created font description and should call
    /// `.free()` when done with it. You can use idiomatic Zig pattern with
    /// `defer`:
    /// ```zig
    /// const font_desc = try pango.FontDescription.new();
    /// defer font_desc.free();
    /// ```
    pub fn new() !*FontDescription {
        const desc = c.pango_font_description_new() orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), desc);
        return desc;
    }

    /// Make a copy of a `pango.FontDescription`.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.FontDescription`.
    ///
    /// **NOTE**: The caller owns the created font description and should call
    /// `.free()` when done with it. You can use idiomatic Zig pattern with
    /// `defer`:
    /// ```zig
    /// const font_desc = try another_desc.copy();
    /// defer font_desc.free();
    /// ```
    pub fn copy(self: *const FontDescription) !*FontDescription {
        const desc = c.pango_font_description_copy(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), desc);
        return desc;
    }

    /// Make a copy of a `pango.FontDescription`, but don’t duplicate allocated
    /// fields.
    ///
    /// This is like `pango.FontDescription.copy()`, but only a shallow copy is
    /// made of the family name and other allocated fields. The result can only
    /// be used until `self` is modified or freed. This is meant to be used
    /// when the copy is only needed temporarily.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.FontDescription`.
    ///
    /// **NOTE**: The caller owns the created font description and should call
    /// `.free()` when done with it. You can use idiomatic Zig pattern with
    /// `defer`:
    /// ```zig
    /// const font_desc = try another_desc.copyStatic();
    /// defer font_desc.free();
    /// ```
    pub fn copyStatic(self: *const FontDescription) !*FontDescription {
        const desc = c.pango_font_description_copy_static(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), desc);
        return desc;
    }

    /// Computes a hash of a `pango.FontDescription` structure.
    ///
    /// The hash value is independent of self->mask.
    pub fn hash(self: *const FontDescription) u32 {
        return @intCast(c.pango_font_description_hash(self));
    }

    /// Compares two font descriptions for equality.
    ///
    /// Two font descriptions are considered equal if the fonts they describe
    /// are provably identical. This means that their masks do not have to
    /// match, as long as other fields are all the same. (Two font descriptions
    /// may result in identical fonts being loaded, but still compare `false`.)
    ///
    /// **Parameters**
    /// - `desc2`: another `pango.FontDescription`
    ///
    /// **Returns**
    ///
    /// `true` if the two font descriptions are identical, `false` otherwise.
    pub fn equal(self: *const FontDescription, other: *const FontDescription) bool {
        return c.pango_font_description_equal(self, other) != 0;
    }

    /// Frees a font description.
    pub fn free(self: *FontDescription) void {
        c.pango_font_description_free(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Frees a slice of font descriptions.
    pub fn freeMany(descs: []?*FontDescription) void {
        c.pango_font_descriptions_free(descs.ptr, @intCast(descs.len));
    }

    /// Sets the family name field of a font description.
    ///
    /// The family name represents a family of related font styles, and will
    /// resolve to a particular `pango.FontFamily`. In some uses of
    /// `pango.FontDescription`, it is also possible to use a comma separated
    /// list of family names for this field.
    ///
    /// **Parameters**
    /// - `family`: a string representing the family name
    pub fn setFamily(self: *FontDescription, family: [:0]const u8) void {
        c.pango_font_description_set_family(self, family);
    }

    /// Sets the family name field of a font description, without copying the
    /// string.
    ///
    /// This is like `pango.FontDescription.setFamily()`, except that no copy
    /// of `family` is made. The caller must make sure that the string passed
    /// in stays around until `self` has been freed or the name is set again.
    /// This function can be used if `family` is a static string such as a
    /// string literal, or if `self` is only needed temporarily.
    ///
    /// **Parameters**
    /// - `family`: a string representing the family name
    pub fn setFamilyStatic(self: *FontDescription, family: [:0]const u8) void {
        c.pango_font_description_set_family_static(self, family);
    }

    /// Gets the family name field of a font description.
    ///
    /// **Returns**
    ///
    /// The family name field for the font description, or empty string if not
    /// previously set. This has the same life-time as the font description
    /// itself and should not be freed.
    ///
    /// **Parameters**
    /// - `family`: a string representing the family name
    pub fn getFamily(self: *const FontDescription) [:0]const u8 {
        const ptr = c.pango_font_description_get_family(self) orelse return &.{};
        return std.mem.span(ptr);
    }

    /// Sets the style field of a `pango.FontDescription`.
    ///
    /// The `pango.Style` enumeration describes whether the font is slanted and
    /// the manner in which it is slanted; it can be either `.Normal`,
    /// `.Italic`, or `.Oblique`.
    ///
    /// Most fonts will either have a italic style or an oblique style, but not
    /// both, and font matching in Pango will match italic specifications with
    /// oblique fonts and vice-versa if an exact match is not found.
    ///
    /// **Parameters**
    /// - `style`: the style for the font description
    pub fn setStyle(self: *FontDescription, style: pango.Style) void {
        c.pango_font_description_set_style(self, style);
    }

    /// Gets the style field of a `pango.FontDescription`.
    ///
    /// See `pango.FontDescription.setStyle()`.
    ///
    /// **Returns**
    ///
    /// the style field for the font description. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getStyle(self: *const FontDescription) pango.Style {
        return c.pango_font_description_get_style(self);
    }

    /// Sets the variant field of a font description.
    ///
    /// The `pango.Variant` can either be `.Normal` or `.SmallCaps`.
    ///
    /// **Parameters**
    /// - `variant`: the variant type for the font description
    pub fn setVariant(self: *FontDescription, variant: pango.Variant) void {
        c.pango_font_description_set_variant(self, variant);
    }

    /// Gets the variant field of a `pango.FontDescription`.
    ///
    /// See `pango.FontDescription.setVariant()`.
    ///
    /// **Returns**
    ///
    /// the variant field for the font description. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getVariant(self: *const FontDescription) pango.Variant {
        return c.pango_font_description_get_variant(self);
    }

    /// Sets the weight field of a font description.
    ///
    /// The weight field specifies how bold or light the font should be. In
    /// addition to the values of the PangoWeight enumeration, other
    /// intermediate numeric values are possible.
    ///
    /// **Parameters**
    /// - `weight`: the weight for the font description
    pub fn setWeight(self: *FontDescription, weight: pango.Weight) void {
        c.pango_font_description_set_weight(self, weight);
    }

    /// Gets the weight field of a font description.
    ///
    /// See `pango.FontDescription.setWeight()`.
    ///
    /// **Returns**
    ///
    /// the weight field for the font description. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getWeight(self: *const FontDescription) pango.Weight {
        return c.pango_font_description_get_weight(self);
    }

    /// Sets the stretch field of a font description.
    ///
    /// The PangoStretch field specifies how narrow or wide the font should be.
    ///
    /// **Parameters**
    /// - `stretch`: the stretch for the font description
    pub fn setStretch(self: *FontDescription, stretch: pango.Stretch) void {
        c.pango_font_description_set_stretch(self, stretch);
    }

    /// Gets the stretch field of a font description.
    ///
    /// See `pango.FontDescription.setStretch()`.
    ///
    /// **Returns**
    ///
    /// the stretch field for the font description. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getStretch(self: *const FontDescription) pango.Stretch {
        return c.pango_font_description_get_stretch(self);
    }

    /// Sets the size field of a font description in fractional points.
    ///
    /// This is mutually exclusive with
    /// `pango.FontDescription.setAbsoluteSize()`.
    ///
    /// **Parameters**
    /// - `size`: the size of the font in points, scaled by `pango.SCALE`.
    /// (That is, a size value of 10 * pango.SCALE is a 10 point font. The
    /// conversion factor between points and device units depends on system
    /// configuration and the output device. For screen display, a logical DPI
    /// of 96 is common, in which case a 10 point font corresponds to a
    /// 10 * (96 / 72) = 13.3 pixel font. Use
    /// `pango.FontDescription.setAbsoluteSize()` if you need a particular size
    /// in device units.
    pub fn setSize(self: *FontDescription, size: i32) void {
        c.pango_font_description_set_size(self, @intCast(size));
    }

    /// Gets the size field of a font description.
    ///
    /// See `pango.FontDescription.setSize()`.
    ///
    /// **Returns**
    ///
    /// the size field for the font description in points or device units. You
    /// must call `pango.FontDescription.getSizeIsAbsolute()` to find out which
    /// is the case. Returns 0 if the size field has not previously been set or
    /// it has been set to 0 explicitly. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getSize(self: *const FontDescription) i32 {
        return @intCast(c.pango_font_description_get_size(self));
    }

    /// Sets the size field of a font description, in device units.
    ///
    /// This is mutually exclusive with `pango.FontDescription.setSize()` which
    /// sets the font size in points.
    ///
    /// **Parameters**
    /// - `size`: the new size, in Pango units. There are `pango.SCALE` Pango
    /// units in one device unit. For an output backend where a device unit is
    /// a pixel, a size value of 10 * pango.SCALE gives a 10 pixel font.
    pub fn setAbsoluteSize(self: *FontDescription, size: f64) void {
        c.pango_font_description_set_absolute_size(self, size);
    }

    /// Determines whether the size of the font is in points (not absolute) or
    /// device units (absolute).
    ///
    /// See `pango.FontDescription.setSize()` and
    /// `pango.FontDescription.setAbsoluteSize()`.
    ///
    /// **Returns**
    ///
    /// whether the size for the font description is in points or device units.
    /// Use `pango.FontDescription.getSetFields()` to find out if the size
    /// field of the font description was explicitly set or not.
    pub fn getSizeIsAbsolute(self: *const FontDescription) bool {
        return c.pango_font_description_get_size_is_absolute(self) != 0;
    }

    /// Sets the gravity field of a font description.
    ///
    /// The gravity field specifies how the glyphs should be rotated. If
    /// gravity is `.Auto`, this actually unsets the gravity mask on the font
    /// description.
    ///
    /// This function is seldom useful to the user. Gravity should normally be
    /// set on a `pango.Context`.
    ///
    /// **Parameters**
    /// - `gravity`: the gravity for the font description
    pub fn setGravity(self: *FontDescription, gravity: pango.Gravity) void {
        c.pango_font_description_set_gravity(self, gravity);
    }

    /// Gets the gravity field of a font description.
    ///
    /// See `pango.FontDescription.setGravity()`.
    ///
    /// **Returns**
    ///
    /// the gravity field for the font description. Use
    /// `pango.FontDescription.getSetFields()` to find out if the field was
    /// explicitly set or not.
    pub fn getGravity(self: *const FontDescription) pango.Gravity {
        return c.pango_font_description_get_gravity(self);
    }

    /// Sets the variations field of a font description.
    ///
    /// OpenType font variations allow to select a font instance by specifying
    /// values for a number of axes, such as width or weight.
    ///
    /// The format of the variations string is
    /// ```code
    /// AXIS1=VALUE,AXIS2=VALUE...
    /// ```
    /// with each AXIS a 4 character tag that identifies a font axis, and each
    /// VALUE a floating point number. Unknown axes are ignored, and values are
    /// clamped to their allowed range.
    ///
    /// Pango does not currently have a way to find supported axes of a font.
    /// Both harfbuzz and freetype have API for this. See for example
    /// [hb_ot_var_get_axis_infos](https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-get-axis-infos).
    ///
    /// **Parameters**
    /// - `variations`: a string representing the variations
    pub fn setVariations(self: *FontDescription, variations: [:0]const u8) void {
        c.pango_font_description_set_variations(self, variations);
    }

    /// Sets the variations field of a font description.
    ///
    /// This is like `pango.FontDescription.setVariations()`, except that no
    /// copy of variations is made. The caller must make sure that the string
    /// passed in stays around until `self` has been freed or the name is set
    /// again. This function can be used if variations is a static string such
    /// as a string literal, or if `self` is only needed temporarily.
    ///
    /// **Parameters**
    /// - `variations`: a string representing the variations
    pub fn setVariationsStatic(self: *FontDescription, variations: [:0]const u8) void {
        c.pango_font_description_set_variations_static(self, variations);
    }

    /// Gets the variations field of a font description
    ///
    /// See `pango.FontDescription.setVariations()`.
    ///
    /// **Returns**
    ///
    /// tvariations field for the font description, or empty string if not
    /// previously set. This has the same life-time as the font description
    /// itself and should not be freed.
    pub fn getVariations(self: *const FontDescription) [:0]const u8 {
        const ptr = c.pango_font_description_get_variations(self) orelse return &.{};
        return std.mem.span(ptr);
    }

    /// Determines which fields in a font description have been set.
    ///
    /// **Returns**
    ///
    /// a bitmask with bits set corresponding to the fields in `self` that have
    /// been set.
    pub fn getSetFields(self: *const FontDescription) pango.FontMask {
        return c.pango_font_description_get_set_fields(self);
    }

    /// Unsets some of the fields in a `pango.FontDescription`.
    ///
    /// The unset fields will get back to their default values.
    ///
    /// **Parameters**
    /// - `to_unset`: bitmask of fields in the `self` to unset.
    pub fn unsetFields(self: *FontDescription, to_unset: pango.FontMask) void {
        c.pango_font_description_unset_fields(self, to_unset);
    }

    /// Merges the fields that are set in `desc_to_merge` into the fields in
    /// `self`.
    ///
    /// If `replace_existing` is `false`, only fields in `self` that are not
    /// already set are affected. If `true`, then fields that are already set
    /// will be replaced as well.
    ///
    /// If `desc_to_merge` is `null`, this function performs nothing.
    ///
    /// **Parameters**
    /// - `desc_to_merge`: the `pango.FontDescription` to merge from, or
    /// `null`.
    /// - `replace_existing`: If `true`, replace fields in `self` with the
    /// corresponding values from `desc_to_merge`, even if they are already
    /// exist.
    pub fn merge(self: *FontDescription, desc_to_merge: ?*const FontDescription, replace_existing: bool) void {
        c.pango_font_description_merge(self, desc_to_merge, if (replace_existing) 1 else 0);
    }

    /// Merges the fields that are set in desc_to_merge into the fields in
    /// `self`, without copying allocated fields.
    ///
    /// This is like `pango.FontDescription.merge()`, but only a shallow copy
    /// is made of the family name and other allocated fields. `self` can only
    /// be used until `desc_to_merge` is modified or freed. This is meant to
    /// be used when the merged font description is only needed temporarily.
    ///
    /// **Parameters**
    /// - `desc_to_merge`: the `pango.FontDescription` to merge from.
    /// - `replace_existing`: If `true`, replace fields in `self` with the
    /// corresponding values from `desc_to_merge`, even if they are already
    /// exist.
    pub fn mergeStatic(self: *FontDescription, desc_to_merge: *const FontDescription, replace_existing: bool) void {
        c.pango_font_description_merge_static(self, desc_to_merge, if (replace_existing) 1 else 0);
    }

    pub fn betterMatch(self: *const FontDescription, old_match: *const FontDescription, new_match: *const FontDescription) bool {
        return c.pango_font_description_better_match(self, old_match, new_match) != 0;
    }

    /// Creates a new font description from a string representation.
    ///
    /// The string must have the form
    /// ```code
    /// "\[FAMILY-LIST] \[STYLE-OPTIONS] \[SIZE] \[VARIATIONS]",
    /// ```
    /// where FAMILY-LIST is a comma-separated list of families optionally
    /// terminated by a comma, STYLE_OPTIONS is a whitespace-separated list of
    /// words where each word describes one of style, variant, weight, stretch,
    /// or gravity, and SIZE is a decimal number (size in points) or optionally
    /// followed by the unit modifier “px” for absolute size. VARIATIONS is a
    /// comma-separated list of font variation specifications of the form
    /// “`axis`=value” (the = sign is optional).
    ///
    /// The following words are understood as styles: “Normal”, “Roman”,
    /// “Oblique”, “Italic”.
    ///
    /// The following words are understood as variants: “Small-Caps”,
    /// “All-Small-Caps”, “Petite-Caps”, “All-Petite-Caps”, “Unicase”,
    /// “Title-Caps”.
    ///
    /// The following words are understood as weights: “Thin”, “Ultra-Light”,
    /// “Extra-Light”, “Light”, “Semi-Light”, “Demi-Light”, “Book”, “Regular”,
    /// “Medium”, “Semi-Bold”, “Demi-Bold”, “Bold”, “Ultra-Bold”, “Extra-Bold”,
    /// “Heavy”, “Black”, “Ultra-Black”, “Extra-Black”.
    ///
    /// The following words are understood as stretch values:
    /// “Ultra-Condensed”, “Extra-Condensed”, “Condensed”, “Semi-Condensed”,
    /// “Semi-Expanded”, “Expanded”, “Extra-Expanded”, “Ultra-Expanded”.
    ///
    /// The following words are understood as gravity values: “Not-Rotated”,
    /// “South”, “Upside-Down”, “North”, “Rotated-Left”, “East”,
    /// “Rotated-Right”, “West”.
    ///
    /// Any one of the options may be absent. If FAMILY-LIST is absent, then
    /// the family_name field of the resulting font description will be
    /// initialized to `null`. If STYLE-OPTIONS is missing, then all style
    /// options will be set to the default values. If SIZE is missing, the size
    /// in the resulting font description will be set to 0.
    ///
    /// A typical example:
    /// ```code
    /// "Cantarell Italic Light 15 \`wght`=200"
    /// ```
    ///
    /// **Parameters**
    /// - `str`: string representation of a font description.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.FontDescription`.
    ///
    /// **NOTE**: The caller owns the created font description and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern with
    /// `defer`:
    /// ```zig
    /// const font_desc = pango.FontDescription.fromString("Roboto");
    /// defer font_desc.free();
    /// ```
    pub fn fromString(str: [:0]const u8) !*FontDescription {
        const desc = c.pango_font_description_from_string(str) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), desc);
        return desc;
    }

    /// Creates a string representation of a font description.
    ///
    /// See `pango.FontDescription.fromString()` for a description of the
    /// format of the string representation. The family list in the string
    /// description will only have a terminating comma if the last word of the
    /// list is a valid style option.
    ///
    /// **Returns**
    ///
    /// a new string that must be freed with `pango.free()`.
    pub fn toString(self: *const FontDescription) ![:0]u8 {
        const ptr = c.pango_font_description_to_string(self) orelse return &.{};
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return std.mem.span(ptr);
    }

    /// Creates a filename representation of a font description.
    ///
    /// The filename is identical to the result from calling
    /// `pango.FontDescription.toString()`, but with underscores instead of
    /// characters that are untypical in filenames, and in lower case only.
    ///
    /// **Returns**
    ///
    /// a new string that must be freed with `pango.free()`.
    pub fn toFilename(self: *const FontDescription) ![:0]u8 {
        const ptr = c.pango_font_description_to_filename(self) orelse return &.{};
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return std.mem.span(ptr);
    }
};
