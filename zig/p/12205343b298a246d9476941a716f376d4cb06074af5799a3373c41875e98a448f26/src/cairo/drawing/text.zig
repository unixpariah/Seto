//! text — Rendering text and glyphs
//!
//! The functions with *text* in their name form cairo's *toy* text API. The
//! toy API takes UTF-8 encoded text and is limited in its functionality to
//! rendering simple left-to-right text with no advanced features. That means
//! for example that most complex scripts like Hebrew, Arabic, and Indic
//! scripts are out of question. No kerning or correct positioning of
//! diacritical marks either. The font selection is pretty limited too and
//! doesn't handle the case that the selected font does not cover the
//! characters in the text. This set of functions are really that, a toy text
//! API, for testing and demonstration purposes. Any serious application should
//! avoid them.
//!
//! The functions with *glyphs* in their name form cairo's *low-level* text
//! API. The low-level API relies on the user to convert text to a set of glyph
//! indexes and positions. This is a very hard problem and is best handled by
//! external libraries, like the pangocairo that is part of the Pango text
//! layout and rendering library. Pango is available from http://www.pango.org/

const std = @import("std");

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const CairoError = cairo.CairoError;

const FontFace = cairo.FontFace;
const FontOptions = cairo.FontOptions;
const ScaledFont = cairo.ScaledFont;

const FontExtents = cairo.FontExtents;
const TextExtents = cairo.TextExtents;

const Context = cairo.Context;
const Matrix = cairo.Matrix;

const FontFaceMixin = @import("../fonts/font_face.zig").Base;

pub const Mixin = struct {
    /// **Note**: The `cr.selectFontFace()` function call is part of what the
    /// cairo designers call the "toy" text API. It is convenient for short
    /// demos and simple programs, but it is not expected to be adequate for
    /// serious text-using applications.
    ///
    /// Selects a family and style of font from a simplified description as a
    /// family name, slant and weight. Cairo provides no operation to list
    /// available family names on the system (this is a "toy", remember), but
    /// the standard CSS2 generic family names, ("serif", "sans-serif",
    /// "cursive", "fantasy", "monospace"), are likely to work as expected.
    ///
    /// If `family` starts with the string "`cairo`:", or if no native font
    /// backends are compiled in, cairo will use an internal font family. The
    /// internal font family recognizes many modifiers in the family string,
    /// most notably, it recognizes the string "monospace". That is, the family
    /// name "`cairo`:monospace" will use the monospace version of the internal
    /// font family.
    ///
    /// For "real" font selection, see the font-backend-specific font_face_create functions for the font backend you are using. (For example, if you are using the freetype-based cairo-ft font backend, see c.cairo_ft_font_face_create_for_ft_face() or c.cairo_ft_font_face_create_for_pattern().) The resulting font face could then be used with c.cairo_scaled_font_create() and c.cairo_set_scaled_font().
    ///
    /// Similarly, when using the "real" font support, you can call directly
    /// into the underlying font system, (such as fontconfig or freetype), for
    /// operations such as listing available fonts, etc.
    ///
    /// It is expected that most applications will need to use a more
    /// comprehensive font handling and text layout library, (for example,
    /// pango), in conjunction with cairo.
    ///
    /// If text is drawn without a call to `cr.selectFontFace()`, (nor
    /// `cr.setFontFace()` nor `cr.setScaledFont()`), the default family is
    /// platform-specific, but is essentially "sans-serif". Default slant is
    /// `cairo.FontFace.FontSlant.Normal`, and default weight is
    /// `cairo.FontFace.FontWeight.Normal`.
    ///
    /// This function is equivalent to a call to c.cairo_toy_font_face_create() followed by c.cairo_set_font_face().
    ///
    /// **Parameters**
    /// - `family`: a font family name, encoded in UTF-8
    /// - `slant`: the slant for the font
    /// - `weight`: the weight for the font
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-select-font-face)
    pub fn selectFontFace(self: *Context, family: [:0]const u8, slant: FontFace.FontSlant, weight: FontFace.FontWeight) void {
        // TODO fix desc
        c.cairo_select_font_face(self, family, slant, weight);
    }

    /// Sets the current font matrix to a scale by a factor of `size`,
    /// replacing any font matrix previously set with `cr.setFontSize()` or
    /// `cr.setFontMatrix()`. This results in a font size of `size` user space
    /// units. (More precisely, this matrix will result in the font's em-square
    /// being a `size` by `size` square in user space.)
    ///
    /// If text is drawn without a call to `cr.setFontSize()`, (nor
    /// `cr.setFontMatrix()` nor `cr.setScaledFont()`), the default font size
    /// is 10.0.
    ///
    /// **Parameters**
    /// - `size`: the new font size, in user space units
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-set-font-size)
    pub fn setFontSize(self: *Context, size: f64) void {
        c.cairo_set_font_size(self, size);
    }

    /// Sets the current font matrix to `matrix`. The font matrix gives a
    /// transformation from the design space of the font (in this space, the
    /// em-square is 1 unit by 1 unit) to user space. Normally, a simple scale
    /// is used (see `cr.setFontSize()`), but a more complex font matrix can
    /// be used to shear the font or stretch it unequally along the two axes
    ///
    /// **Parameters**
    /// - `matrix`: a `cairo.Matrix` describing a transform to be applied to
    /// the current font.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-set-font-matrix)
    pub fn setFontMatrix(self: *Context, matrix: *const Matrix) void {
        c.cairo_set_font_matrix(self, matrix);
    }

    /// Gets the current font matrix. See `cr.setFontMatrix()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-get-font-matrix)
    pub fn getFontMatrix(self: *Context) Matrix {
        var m: Matrix = undefined;
        c.cairo_get_font_matrix(self, &m);
        return m;
    }

    /// Sets a set of custom font rendering options for the `cairo.Context`.
    /// Rendering options are derived by merging these options with the options
    /// derived from underlying surface; if the value in options has a default
    /// value (like `cairo.Antialias.Default`), then the value from the surface
    /// is used.
    ///
    /// **Parameters**
    /// - `options`: font options to use
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-set-font-options)
    pub fn setFontOptions(self: *Context, options: *const FontOptions) void {
        c.cairo_set_font_options(self, options);
    }

    /// Retrieves font rendering options set via
    /// `cairo.Context.setFontOptions()`. Note that the returned options do not
    /// include any options derived from the underlying surface; they are
    /// literally the options passed to `cairo.Context.setFontOptions()`.
    ///
    /// **Parameters**
    /// - `options`: a `cairo.FontOptions` object into which to store the
    /// retrieved options. All existing values are overwritten
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-get-font-options)
    pub fn getFontOptions(self: *Context, options: *FontOptions) void {
        c.cairo_get_font_options(self, options);
    }

    /// Replaces the current `cairo.FontFace` object in the `self` with
    /// `font_face`. The replaced font face in the `cairo.Context` will be
    /// destroyed if there are no other references to it.
    ///
    /// **Parameters**
    /// - `font_face`: a `cairo.FontFace`, or `null` to restore to the default
    /// font
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-set-font-face)
    pub fn setFontFace(self: *Context, font_face: ?*FontFace) void {
        c.cairo_set_font_face(self, font_face);
    }

    /// Gets the current font face for a `cairo.Context`.
    ///
    /// **Returns**
    ///
    /// the current font face. This object is owned by cairo. To keep a
    /// reference to it, you must call `.reference()` on it. If memory cannot
    /// be allocated, `error.OutOfMemory` will be raised.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-get-font-face)
    pub fn getFontFace(self: *Context) CairoError!*FontFace {
        const font_face = c.cairo_get_font_face(self).?;
        try font_face.status().toErr();
        return font_face;
    }

    /// Replaces the current font face, font matrix, and font options in the
    /// `cairo.Context` with those of the `cairo.ScaledFont`. Except for some
    /// translation, the current CTM of the `cairo.Context` should be the same
    /// as that of the `cairo.ScaledFont`, which can be accessed using
    /// `cairo.ScaledFont.getCtm()`.
    ///
    /// **Parameters**
    /// - `scaled_font`: a `cairo.ScaledFont`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-set-scaled-font)
    pub fn setScaledFont(self: *Context, scaled_font: *const ScaledFont) void {
        c.cairo_set_scaled_font(self, scaled_font);
    }

    /// Gets the current scaled font for a `cairo.Context`.
    ///
    /// **Returns**
    ///
    /// the current scaled font. This object is owned by cairo. To keep a
    /// reference to it, you must call `.reference()` on it. If memory cannot
    /// be allocated, `error.OutOfMemory` will be raised.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-get-scaled-font)
    pub fn getScaledFont(self: *Context) CairoError!*ScaledFont {
        const scaled_font = c.cairo_get_scaled_font(self).?;
        try scaled_font.status().toErr();
        return scaled_font;
    }

    /// A drawing operator that generates the shape from a string of UTF-8
    /// characters, rendered according to the current font_face, font_size
    /// (font_matrix), and font_options.
    ///
    /// This function first computes a set of glyphs for the string of text.
    /// The first glyph is placed so that its origin is at the current point.
    /// The origin of each subsequent glyph is offset from that of the previous
    /// glyph by the advance values of the previous glyph.
    ///
    /// After this call the current point is moved to the origin of where the
    /// next glyph would be placed in this same progression. That is, the
    /// current point will be at the origin of the final glyph offset by its
    /// advance values. This allows for easy display of a single logical string
    /// with multiple calls to `cairo.Context.showText()`.
    ///
    /// Note: The `cr.showText()` function call is part of what the cairo
    /// designers call the "toy" text API. It is convenient for short demos and
    /// simple programs, but it is not expected to be adequate for serious
    /// text-using applications. See `cairo.Context.showGlyphs()` for the
    /// "real" text display API in cairo.
    ///
    /// **Parameters**
    /// - `utf8`: a 0-sentinel string of text encoded in UTF-8, or `null`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-show-text)
    pub fn showText(self: *Context, utf8: ?[:0]const u8) void {
        c.cairo_show_text(self, utf8 orelse null);
    }

    /// A drawing operator that generates the shape from a slice of glyphs,
    /// rendered according to the current font face, font size (font matrix),
    /// and font options.
    ///
    /// **Parameters**
    /// - `glyphs`: slice of glyphs to show
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-show-glyphs)
    pub fn showGlyphs(self: *Context, glyphs: []const Glyph) void {
        c.cairo_show_glyphs(self, glyphs.ptr, @intCast(glyphs.len));
    }

    /// This operation has rendering effects similar to
    /// `cairo.Context.showGlyphs()` but, if the target surface supports it,
    /// uses the provided text and cluster mapping to embed the text for the
    /// glyphs shown in the output. If the target does not support the extended
    /// attributes, this function acts like the basic
    /// `cairo.Context.showGlyphs()` as if it had been passed `glyphs`.
    ///
    /// The mapping between `utf8` and `glyphs` is provided by an slice of
    /// *clusters*. Each cluster covers a number of text bytes and glyphs, and
    /// neighboring clusters cover neighboring areas of `utf8` and `glyphs`.
    /// The clusters should collectively cover `utf8` and `glyphs` in entirety.
    ///
    /// The first cluster always covers bytes from the beginning of `utf8`. If
    /// `cluster_flags` is not `.Backward`, the first cluster also covers the
    /// beginning of `glyphs`, otherwise it covers the end of the glyphs array
    /// and following clusters move backward.
    ///
    /// See `cairo.TextCluster` for constraints on valid clusters.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-show-text-glyphs)
    pub fn showTextGlyphs(self: *Context, utf8: [:0]const u8, glyphs: []const Glyph, clusters: []const TextCluster, cluster_flags: TextCluster.Flags) void {
        c.cairo_show_text_glyphs(
            self,
            utf8,
            @intCast(utf8.len),
            glyphs.ptr,
            @intCast(glyphs.len),
            clusters.ptr,
            @intCast(clusters.len),
            cluster_flags,
        );
    }

    /// Gets the font extents for the currently selected font.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-font-extents)
    pub fn fontExtents(self: *Context) FontExtents {
        var extents: FontExtents = undefined;
        c.cairo_font_extents(self, &extents);
        return extents;
    }

    /// Gets the extents for a string of text. The extents describe a
    /// user-space rectangle that encloses the "inked" portion of the text, (as
    /// it would be drawn by `cairo.Context.showText()`). Additionally, the
    /// `x_advance` and `y_advance` values indicate the amount by which the
    /// current point would be advanced by `cairo.Context.showText()`.
    ///
    /// Note that whitespace characters do not directly contribute to the size
    /// of the rectangle (`.width` and `.height`). They do contribute
    /// indirectly by changing the position of non-whitespace characters. In
    /// particular, trailing whitespace characters are likely to not affect the
    /// size of the rectangle, though they will affect the `x_advance` and
    /// `y_advance` values.
    ///
    /// **Parameters**
    /// - `utf8`: a 0-sentinel string of text encoded in UTF-8, or `null`
    ///
    /// **Returns**
    ///
    /// a `cairo.TextExtents` object with the results.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-text-extents)
    pub fn textExtents(self: *Context, utf8: ?[:0]const u8) TextExtents {
        var extents: TextExtents = undefined;
        c.cairo_text_extents(self, utf8 orelse null, &extents);
        return extents;
    }

    /// Gets the extents for an array of glyphs. The extents describe a
    /// user-space rectangle that encloses the "inked" portion of the glyphs,
    /// (as they would be drawn by `cairo.Context.showGlyphs()`). Additionally,
    /// the `x_advance` and `y_advance` values indicate the amount by which the
    /// current point would be advanced by `cairo.Context.showGlyphs()`.
    ///
    /// Note that whitespace glyphs do not contribute to the size of the
    /// rectangle (`.width` and `.height`).
    ///
    /// **Parameters**
    /// - `glyphs`: a slice of `cairo.Glyph` objects
    ///
    /// **Returns**
    ///
    /// a `cairo.TextExtents` object with the results.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-glyph-extents)
    pub fn glyphExtents(self: *Context, glyphs: []const Glyph) TextExtents {
        var extents: TextExtents = undefined;
        c.cairo_glyph_extents(self, glyphs.ptr, @intCast(glyphs.len), &extents);
        return extents;
    }
};

/// The `cairo.Glyph` structure holds information about a single glyph when
/// drawing or measuring text. A font is (in simple terms) a collection of
/// shapes used to draw text. A glyph is one of these shapes. There can be
/// multiple glyphs for a single character (alternates to be used in different
/// contexts, for example), or a glyph can be a *ligature* of multiple
/// characters. Cairo doesn't expose any way of converting input text into
/// glyphs, so in order to use the Cairo interfaces that take arrays of glyphs,
/// you must directly access the appropriate underlying font system.
///
/// Note that the offsets given by `x` and `y` are not cumulative. When drawing
/// or measuring text, each glyph is individually positioned with respect to
/// the overall origin
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-glyph-t)
pub const Glyph = extern struct {
    /// glyph index in the font. The exact interpretation of the glyph index
    /// depends on the font technology being used.
    index: c_ulong,
    /// the offset in the X direction between the origin used for drawing or
    /// measuring the string and the origin of this glyph.
    x: f64,
    /// the offset in the Y direction between the origin used for drawing or
    /// measuring the string and the origin of this glyph.
    y: f64,

    /// Allocates a slice of `cairo.Glyph`'s. This function is only useful in
    /// implementations of c.cairo_user_scaled_font_text_to_glyphs_func_t where
    /// the user needs to allocate a slice of glyphs that cairo will free. For
    /// all other uses, user can use their own allocation method for glyphs.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-glyph-allocate)
    pub fn allocate(num_glyphs: usize) error{OutOfMemory}![]Glyph {
        // TODO: fix desc
        const ptr: [*]Glyph = c.cairo_glyph_allocate(@intCast(num_glyphs)) orelse return error.OutOfMemory;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr[0..num_glyphs];
    }

    /// Frees a slice of `cairo.Glyph`'s allocated using
    /// `cairo.Glyph.allocate()`. This function is only useful to free glyph
    /// slice returned by `cairo.ScaledFont.textToGlyphs()` where cairo returns
    /// a slice of glyphs that the user will free. For all other uses, user can
    /// use their own allocation method for glyphs.
    ///
    /// **Parameters**
    /// - `glyphs`: slice of glyphs to free
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-glyph-free)
    pub fn free(glyphs: []Glyph) void {
        c.cairo_glyph_free(glyphs.ptr);
        if (safety.tracing) safety.destroy(glyphs.ptr);
    }
};

/// The `cairo.TextCluster` structure holds information about a single *text
/// cluster*. A text cluster is a minimal mapping of some glyphs corresponding
/// to some UTF-8 text.
///
/// For a cluster to be valid, both `num_bytes` and `num_glyphs` should be
/// non-negative, and at least one should be non-zero. Note that clusters with
/// zero glyphs are not as well supported as normal clusters. For example, PDF
/// rendering applications typically ignore those clusters when PDF text is
/// being selected.
///
/// See `cairo.Context.showTextGlyphs()` for how clusters are used in advanced
/// text operations.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-text-cluster-t)
pub const TextCluster = extern struct {
    /// the number of bytes of UTF-8 text covered by cluster
    num_bytes: c_int,
    /// the number of glyphs covered by cluster
    num_glyphs: c_int,

    /// Specifies properties of a text cluster mapping.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-text-cluster-flags-t)
    pub const Flags = enum(c_uint) {
        None,
        /// The clusters in the cluster array map to glyphs in the glyph array from
        /// end to start.
        Backward = 1,
    };

    /// Allocates a slice of `cairo.TextCluster`'s. This function is only
    /// useful in implementations of c.cairo_user_scaled_font_text_to_glyphs_func_t
    /// where the user needs to allocate a slice of text clusters that cairo
    /// will free. For all other uses, user can use their own allocation method
    /// for text clusters.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-text-cluster-allocate)
    pub fn allocate(numClusters: usize) error{OutOfMemory}![]TextCluster {
        // TODO: fix desc
        const clusters: [*]TextCluster = c.cairo_text_cluster_allocate(@intCast(numClusters)) orelse return error.OutOfMemory;
        return clusters[0..numClusters];
    }

    /// Frees a slice of `cairo.TextCluster`'s allocated using
    /// `cairo.TextCluster.allocate()`. This function is only useful to free
    /// text cluster array returned by `cairo.ScaledFont.textToGlyphs()` where
    /// cairo returns a slice of text clusters that the user will free. For all
    /// other uses, user can use their own allocation method for text clusters.
    ///
    /// **Parameters**
    /// - `clusters`: slice of text clusters to free
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-text-cluster-free)
    pub fn free(clusters: []TextCluster) void {
        c.cairo_text_cluster_free(clusters.ptr);
        if (safety.tracing) safety.destroy(clusters.ptr);
    }
};

pub const ToyFontFace = opaque {
    pub usingnamespace FontFaceMixin(@This());
    /// Creates a font face from a triplet of family, slant, and weight. These
    /// font faces are used in implementation of the the `cairo.Context` "toy"
    /// font API.
    ///
    /// If `family` is the zero-length string "", the platform-specific default
    /// family is assumed. The default family then can be queried using
    /// `cairo.ToyFontFace.getFamily()`.
    ///
    /// The `cairo.Context.selectFontFace()` function uses this to create font
    /// faces. See that function for limitations and other details of toy font
    /// faces.
    ///
    /// **Parameters**
    /// - `family`: a font family name, encoded in UTF-8
    /// - `slant`: the slant for the font
    /// - `weight`: the weight for the font
    ///
    /// **Returns**
    ///
    /// a newly created `cairo.ToyFontFace`.
    ///
    /// **NOTE**: The caller owns the created font face and should call
    /// `font_face.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const font_face = cairo.ToyFontFace.create("", .Normal, .Normal);
    /// defer font_face.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-toy-font-face-create)
    pub fn create(family: ?[:0]const u8, slant: FontFace.FontSlant, weight: FontFace.FontWeight) CairoError!*ToyFontFace {
        const font_face = c.cairo_toy_font_face_create(family orelse null, slant, weight) orelse
            return CairoError.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), font_face);
        try font_face.status().toErr();
        return font_face;
    }

    /// Gets the familly name of a toy font.
    ///
    /// **Returns**
    ///
    /// the family name. This string is owned by the font face and remains
    /// valid as long as the font face is alive (referenced).
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-family)
    pub fn getFamily(self: *ToyFontFace) [:0]const u8 {
        return std.mem.span(c.cairo_toy_font_face_get_family(self));
    }

    /// Gets the slant a toy font.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-slant)
    pub fn getSlant(self: *ToyFontFace) FontFace.FontSlant {
        return c.cairo_toy_font_face_get_slant(self);
    }

    /// Gets the weight a toy font.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-toy-font-face-get-weight)
    pub fn getWeight(self: *ToyFontFace) FontFace.FontWeight {
        return c.cairo_toy_font_face_get_weight(self);
    }
};
