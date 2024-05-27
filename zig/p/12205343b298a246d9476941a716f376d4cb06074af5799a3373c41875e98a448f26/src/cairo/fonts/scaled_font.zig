//! `cairo.ScaledFont` — Font face at particular size and options
//!
//! `cairo.ScaledFont` represents a realization of a font face at a particular
//! size and transformation and a certain set of font options.

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const CairoError = cairo.CairoError;
const DestroyFn = cairo.DestroyFn;
const FontFace = cairo.FontFace;
const FontOptions = cairo.FontOptions;
const Glyph = cairo.Glyph;
const Matrix = cairo.Matrix;
const Status = cairo.Status;
const TextCluster = cairo.TextCluster;
const UserDataKey = cairo.UserDataKey;

/// A `cairo.ScaledFont` is a font scaled to a particular size and device
/// resolution. A `cairo.ScaledFont` is most useful for low-level font usage
/// where a library or application wants to cache a reference to a scaled font
/// to speed up the computation of metrics.
///
/// There are various types of scaled fonts, depending on the font backend they
/// use. The type of a scaled font can be queried using
/// `cairo.ScaledFont.getType()`.
///
/// Memory management of `cairo.ScaledFont` is done with `.reference()` and
/// `.destroy()`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-t)
pub const ScaledFont = opaque {
    /// Creates a `cairo.ScaledFont` object from a font face and matrices that
    /// describe the size of the font and the environment in which it will be
    /// used.
    ///
    /// **Parameters**
    /// - `font_face`: a `cairo.FontFace`
    /// - `font_matrix`: font space to user space transformation matrix for the
    /// font. In the simplest case of a N point font, this matrix is just a
    /// scale by N, but it can also be used to shear the font or stretch it
    /// unequally along the two axes. See `cairo.Context.setFontMatrix()`.
    /// - `ctm`: user to device transformation matrix with which the font will
    /// be used.
    /// - `options`: options to use when getting metrics for the font and
    /// rendering with it.
    ///
    /// **Returns**
    ///
    /// a newly created `cairo.ScaledFont`. If memory cannot be allocated, an
    /// `error.OutOfMemory` will be raised.
    ///
    /// **NOTE**: The caller owns the created object and should call
    /// `.destroy()` on it when done with. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const scaled_font = cairo.ScaledFont.create(...);
    /// defer scaled_font.destroy();
    /// ```
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-create)
    pub fn create(font_face: *FontFace, font_matrix: *const Matrix, ctm: *const Matrix, options: *const FontOptions) CairoError!*ScaledFont {
        // TODO: expand doc example? or not?
        const scaled = c.cairo_scaled_font_create(font_face, font_matrix, ctm, options).?;
        try scaled.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), scaled);
        return scaled;
    }

    /// Increases the reference count on `self` by one. This prevents `self`
    /// from being destroyed until a matching call to `.destroy()` is made.
    ///
    /// Use `cairo.ScaledFont.getReferenceCount()` to get the number of
    /// references to a `cairo.ScaledFont`.
    ///
    /// **Returns**
    ///
    /// the referenced `cairo.ScaledFont`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-reference)
    pub fn reference(self: *ScaledFont) *ScaledFont {
        if (safety.tracing) safety.reference(@returnAddress(), self);
        return c.cairo_scaled_font_reference(self).?;
    }

    /// Decreases the reference count on `self` by one. If the result is zero,
    /// then font and all associated resources are freed. See
    /// `cairo.ScaledFont.reference()`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-destroy)
    pub fn destroy(self: *ScaledFont) void {
        c.cairo_scaled_font_destroy(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Checks whether an error has previously occurred for this
    /// `cairo.ScaledFont`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-status)
    pub fn status(self: *ScaledFont) Status {
        return c.cairo_scaled_font_status(self);
    }

    /// Gets the metrics for a `cairo.ScaledFont`.
    ///
    /// **Returns**
    ///
    /// a `cairo.FontExtents` with the retrieved extents.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-extents)
    pub fn fontExtents(self: *ScaledFont) FontExtents {
        var extents: FontExtents = undefined;
        c.cairo_scaled_font_extents(self, &extents);
        return extents;
    }

    /// Gets the extents for a string of text. The extents describe a
    /// user-space rectangle that encloses the "inked" portion of the text
    /// drawn at the origin (0,0) (as it would be drawn by
    /// `cairo.Context.showText()` if the cairo graphics state were set to the
    /// same font_face, font_matrix, ctm, and font_options as `self`).
    /// Additionally, the `x_advance` and `y_advance` values indicate the
    /// amount by which the current point would be advanced by `cr.showText().
    ///
    /// Note that whitespace characters do not directly contribute to the size
    /// of the rectangle (`.width` and `.height`). They do contribute
    /// indirectly by changing the position of non-whitespace characters. In
    /// particular, trailing whitespace characters are likely to not affect the
    /// size of the rectangle, though they will affect the `x_advance` and
    /// `y_advance` values.
    ///
    /// **Parameters**
    /// - `utf8`: a 0-sentinel string of text, encoded in UTF-8
    ///
    /// **Returns**
    ///
    /// a `cairo.TextExtents` with the retrieved extents.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-text-extents)
    pub fn textExtents(self: *ScaledFont, utf8: [:0]const u8) TextExtents {
        var text_extents: TextExtents = undefined;
        c.cairo_scaled_font_text_extents(self, utf8, &text_extents);
        return text_extents;
    }

    /// Gets the extents for a slice of glyphs. The extents describe a
    /// user-space rectangle that encloses the "inked" portion of the glyphs,
    /// (as they would be drawn by `cairo.Context.showGlyphs()` if the cairo
    /// graphics state were set to the same font_face, font_matrix, ctm, and
    /// font_options as scaled_font ). Additionally, the `x_advance` and
    /// `y_advance` values indicate the amount by which the current point would
    /// be advanced by `cairo.Context.showGlyphs()`.
    ///
    /// Note that whitespace glyphs do not contribute to the size of the
    /// rectangle (extents.width and extents.height).
    ///
    /// **Parameters**
    /// - `glyphs`: a slice of glyph IDs with X and Y offsets.
    ///
    /// **Returns**
    ///
    /// a `cairo.TextExtents` with the retrieved extents.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-glyph-extents)
    pub fn glyphExtents(self: *ScaledFont, glyphs: []const Glyph) TextExtents {
        var extents: TextExtents = undefined;
        c.cairo_scaled_font_glyph_extents(self, glyphs.ptr, @intCast(glyphs.len), &extents);
        return extents;
    }

    /// Converts UTF-8 text to a slice of glyphs, optionally with cluster
    /// mapping, that can be used to render later using `self` scaled font.
    ///
    /// If `glyphs` initially points to a non-zero size slice, that slice is
    /// used as a glyph buffer. If the provided glyph array is too short for
    /// the conversion, a new glyph array is allocated using
    /// `cairo.Glyph.allocate()` and placed in `glyphs`. Upon return,
    /// `num_glyphs` always contains the number of generated glyphs. If the
    /// value `glyphs` points to has changed after the call, the user is
    /// responsible for freeing the allocated glyph slice using
    /// `cairo.Glyph.free()`. This may happen even if the provided array was
    /// large enough.
    ///
    /// If clusters is not NULL, num_clusters and cluster_flags should not be NULL, and cluster mapping will be computed. The semantics of how cluster array allocation works is similar to the glyph array. That is, if clusters initially points to a non-NULL value, that array is used as a cluster buffer, and num_clusters should point to the number of cluster entries available there. If the provided cluster array is too short for the conversion, a new cluster array is allocated using c.cairo_text_cluster_allocate() and placed in clusters . Upon return, num_clusters always contains the number of generated clusters. If the value clusters points at has changed after the call, the user is responsible for freeing the allocated cluster array using c.cairo_text_cluster_free(). This may happen even if the provided array was large enough
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-text-to-glyphs)
    pub fn textToGlyphs(
        self: *ScaledFont,
        x: f64,
        y: f64,
        utf8: [:0]const u8,
        glyphs: *[]Glyph,
        clusters: *[]TextCluster,
        cluster_flags: *TextCluster.Flags,
    ) CairoError!void {
        const glyph_ptr: [*c][*c]Glyph = @ptrCast(@alignCast(glyphs));
        var glyphs_num: c_int = @intCast(glyphs.len);
        const cluster_ptr: [*c][*c]TextCluster = @ptrCast(@alignCast(clusters));
        var clusters_num: c_int = @intCast(clusters.len);
        try c.cairo_scaled_font_text_to_glyphs(
            self,
            x,
            y,
            utf8.ptr,
            @intCast(utf8.len),
            glyph_ptr,
            &glyphs_num,
            cluster_ptr,
            &clusters_num,
            cluster_flags,
        ).toErr();
        if (safety.tracing) {
            if (@intFromPtr(glyphs) != @intFromPtr(glyph_ptr)) try safety.markForLeakDetection(@returnAddress(), glyph_ptr.*);
        }
    }

    /// Gets the font face that this scaled font uses. This might be the font
    /// face passed to `cairo.ScaledFont.create()`, but this does not hold true
    /// for all possible cases.
    ///
    /// **Returns**
    ///
    /// The `cairo.FontFace` with which 'self' was created. This object is
    /// owned by cairo. To keep a reference to it, you must call `.reference()`
    /// on it.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-face)
    pub fn getFontFace(self: *ScaledFont) *FontFace {
        return c.cairo_scaled_font_get_font_face(self).?;
    }

    /// Stores the font options with which `self` was created into `options`
    ///
    /// **Parameters**
    /// - `options`: return value for the font options
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-options)
    pub fn getFontOptions(self: *ScaledFont, options: *FontOptions) void {
        c.cairo_scaled_font_get_font_options(self, options);
    }

    /// Gets the font matrix with which `self` was created.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-font-matrix)
    pub fn getFontMatrix(self: *ScaledFont) Matrix {
        var m: Matrix = undefined;
        c.cairo_scaled_font_get_font_matrix(self, &m);
        return m;
    }

    /// Gets the CTM with which `self` was created. Note that the translation
    /// offsets `(x0, y0)` of the CTM are ignored by
    /// `cairo.ScaledFont.create()`. So, the matrix this function returns
    /// always has `0,0` as `x0,y0`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-ctm)
    pub fn getCtm(self: *ScaledFont) Matrix {
        var ctm: Matrix = undefined;
        c.cairo_scaled_font_get_ctm(self, &ctm);
        return ctm;
    }

    /// Gets the scale matrix of `self`. The scale matrix is product of the
    /// font matrix and the ctm associated with the scaled font, and hence is
    /// the matrix mapping from font space to device space.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-scale-matrix)
    pub fn getScaleMatrix(self: *ScaledFont) Matrix {
        var m: Matrix = undefined;
        c.cairo_scaled_font_get_scale_matrix(self, &m);
        return m;
    }

    /// This function returns the type of the backend used to create a scaled
    /// font. See `cairo.FontFace.Type` for available types. However, this
    /// function never returns `cairo.FontFace.Type.Toy`.
    ///
    /// **Returns**
    ///
    /// the type of `self`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-type)
    pub fn getType(self: *ScaledFont) FontFace.Type {
        return c.cairo_scaled_font_get_type(self);
    }

    /// Returns the current reference count of `self`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-reference-count)
    pub fn getReferenceCount(self: *ScaledFont) usize {
        return @intCast(c.cairo_scaled_font_get_reference_count(self));
    }

    /// Attach user data to `self`. To remove user data from a surface, call
    /// this function with the key that was used to set it and `null` for
    /// `data`.
    ///
    /// **Parameters**
    /// - `key`: the address of a `cairo.UserDataKey` to attach the user data
    /// to
    /// - `user_data`: the user data to attach to the `cairo.ScaledFont`
    /// - `destroyFn`: a `cairo.DestroyFn` which will be called when the
    /// `cairo.Context` is destroyed or when new user data is attached using
    /// the same key.
    ///
    /// The only possible error is `error.OutOfMemory` if a slot could not be
    /// allocated for the user data.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-set-user-data)
    pub fn setUserData(self: *ScaledFont, key: *const UserDataKey, user_data: ?*anyopaque, destroyFn: DestroyFn) CairoError!void {
        try c.cairo_scaled_font_set_user_data(self, key, user_data, destroyFn).toErr();
    }

    /// Return user data previously attached to `self` using the specified key.
    /// If no user data has been attached with the given key this function
    /// returns `null`.
    ///
    /// **Parameters**
    /// - `key`: the address of the `cairo.UserDataKey` the user data was
    /// attached to
    ///
    /// **Returns**
    ///
    /// the user data previously attached or `null`.
    ///
    /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html#cairo-scaled-font-get-user-data)
    pub fn getUserData(self: *ScaledFont, key: *const UserDataKey) ?*anyopaque {
        return c.cairo_scaled_font_get_user_data(self, key);
    }
};

/// The `cairo.FontExtents` structure stores metric information for a font.
/// Values are given in the current user-space coordinate system.
///
/// Because font metrics are in user-space coordinates, they are mostly, but
/// not entirely, independent of the current transformation matrix. If you call
/// `cr.scale(2.0, 2.0)`, text will be drawn twice as big, but the reported
/// text extents will not be doubled. They will change slightly due to hinting
/// (so you can't assume that metrics are independent of the transformation
/// matrix), but otherwise will remain unchanged.
///
///
pub const FontExtents = extern struct {
    /// the distance that the font extends above the baseline. Note that this
    /// is not always exactly equal to the maximum of the extents of all the
    /// glyphs in the font, but rather is picked to express the font designer's
    /// intent as to how the font should align with elements above it.
    ascent: f64,
    /// the distance that the font extends below the baseline. This value is
    /// positive for typical fonts that include portions below the baseline.
    /// Note that this is not always exactly equal to the maximum of the
    /// extents of all the glyphs in the font, but rather is picked to express
    /// the font designer's intent as to how the font should align with
    /// elements below it.
    descent: f64,
    /// the recommended vertical distance between baselines when setting
    /// consecutive lines of text with the font. This is greater than
    /// `ascent + descent` by a quantity known as the line spacing or external
    /// leading. When space is at a premium, most fonts can be set with only a
    /// distance of `ascent + descent` between lines.
    height: f64,
    /// the maximum distance in the X direction that the origin is advanced for
    /// any glyph in the font.
    max_x_advance: f64,
    /// the maximum distance in the Y direction that the origin is advanced for
    /// any glyph in the font. This will be zero for normal fonts used for
    /// horizontal writing. (The scripts of East Asia are sometimes written
    /// vertically.)
    max_y_advance: f64,
};

/// The `cairo.TextExtents` structure stores the extents of a single glyph or a
/// string of glyphs in user-space coordinates. Because text extents are in
/// user-space coordinates, they are mostly, but not entirely, independent of
/// the current transformation matrix. If you call `cr.scale(2.0, 2.0)`, text
/// will be drawn twice as big, but the reported text extents will not be
/// doubled. They will change slightly due to hinting (so you can't assume that
/// metrics are independent of the transformation matrix), but otherwise will
/// remain unchanged.
pub const TextExtents = extern struct {
    /// the horizontal distance from the origin to the leftmost part of the
    /// glyphs as drawn. Positive if the glyphs lie entirely to the right of
    /// the origin.
    x_bearing: f64,
    /// the vertical distance from the origin to the topmost part of the glyphs
    /// as drawn. Positive only if the glyphs lie completely below the origin;
    /// will usually be negative.
    y_bearing: f64,
    /// width of the glyphs as drawn
    width: f64,
    /// height of the glyphs as drawn
    height: f64,
    /// distance to advance in the X direction after drawing these glyphs
    x_advance: f64,
    /// distance to advance in the Y direction after drawing these glyphs. Will
    /// typically be zero except for vertical text layout as found in
    /// East-Asian languages.
    y_advance: f64,
};
