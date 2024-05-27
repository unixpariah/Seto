const build = @import("build_options");
const pango = @import("../pango.zig");
const c = pango.c;
const safety = pango.safety;

const Direction = pango.Direction;

/// A `pango.Context` stores global information used to control the itemization
/// process.
///
/// The information stored by `pango.Context` includes the fontmap used to look
/// up fonts, and default values such as the default language, default gravity,
/// or default font.
///
/// To obtain a `pango.Context`, use `pango.FontMap.createContext()`.
pub const Context = opaque {
    pub usingnamespace @import("pangocairo").pango_context;

    // TODO: fix desc
    /// Creates a new `pango.Context` initialized to default values.
    ///
    /// This function is not particularly useful as it should always be
    /// followed by a `pango.Context.setFontMap()` call, and the function
    /// pango_font_map_create_context() does these two steps together and hence
    /// users are recommended to use that.
    ///
    /// If you are using Pango as part of a higher-level system, that system
    /// may have it’s own way of create a `pango.Context`. For instance, the
    /// GTK toolkit has, among others, `gtk_widget_get_pango_context()`. Use
    /// those instead.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.Context`.
    ///
    /// **NOTE**: The caller owns the created context and should call
    /// `context.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const context = pango.Context.create();
    /// defer context.destroy();
    /// ```
    pub fn create() !*Context {
        const context = c.pango_context_new() orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), context);
        return context;
    }

    pub fn destroy(self: *Context) void {
        c.g_object_unref(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Forces a change in the context, which will cause any PangoLayout using
    /// this context to re-layout.
    ///
    /// This function is only useful when implementing a new backend for Pango,
    /// something applications won’t do. Backends should call this function if
    /// they have attached extra data to the context and such data is changed.
    pub fn changed(self: *Context) void {
        c.pango_context_changed(self);
    }

    /// Sets the font map to be searched when fonts are looked-up in this
    /// context.
    ///
    /// This is only for internal use by Pango backends, a `pango.Context`
    /// obtained via one of the recommended methods should already have a
    /// suitable font map.
    ///
    /// **Parameters**
    /// - `font_map`: the `pango.FontMap` to set, can be `null`, the data is
    /// owned by the caller of the method.
    pub fn setFontMap(self: *Context, font_map: ?*pango.FontMap) void {
        c.pango_context_set_font_map(self, font_map);
    }

    /// Gets the `pango.FontMap` used to look up fonts for this context.
    ///
    /// **Returns**
    ///
    /// the font map for the `pango.Context` This value is owned by Pango and
    /// should not be destroyed. The data is owned by the instance of
    /// `pango.Context`. The return value can be NULL.
    pub fn getFontMap(self: *Context) ?*pango.FontMap {
        return c.pango_context_get_font_map(self).?;
    }

    /// Returns the current serial number of `self`.
    ///
    /// The serial number is initialized to an small number larger than zero
    /// when a new context is created and is increased whenever the context is
    /// changed using any of the setter functions, or the `pango.FontMap` it
    /// uses to find fonts has changed. The serial may wrap, but will never
    /// have the value 0. Since it can wrap, never compare it with “less than”,
    /// always use “not equals”.
    ///
    /// This can be used to automatically detect changes to a `pango.Context`,
    /// and is only useful when implementing objects that need update when
    /// their `pango.Context` changes, like `pango.Layout`.
    ///
    /// **Returns**
    ///
    /// the current serial number of `self`.
    pub fn getSerial(self: *Context) u32 {
        return @intCast(c.pango_context_get_serial(self));
    }

    // /// List all families for a context.
    // ///
    // /// **Parameters**
    // /// - `families`:
    // pub fn listFamilies(self: *Context) void {

    // }
    // pango_context_list_families(context: ?*pango.Context, families: [*c][*c][*c]pango.FontFamily, n_families: [*c]c_int) void;

    /// Set the default font description for the context.
    ///
    /// **Parameters**
    /// - `desc`: the new pango font description
    pub fn setFontDescription(self: *Context, desc: *const pango.FontDescription) void {
        c.pango_context_set_font_description(self, desc);
    }

    /// Retrieve the default font description for the context.
    ///
    /// **Returns**
    ///
    /// a pointer to the context’s default font description. This value must
    /// not be modified or freed.
    pub fn getFontDescription(self: *Context) ?*const pango.FontDescription {
        return c.pango_context_get_font_description(self);
    }

    /// Sets the global language tag for the context.
    ///
    /// The default language for the locale of the running process can be found
    /// using `pango.Language.getDefault()`.
    ///
    /// **Parameters**
    /// - `language`: the new language tag
    pub fn setLanguage(self: *Context, language: *pango.Language) void {
        return c.pango_context_set_language(self, language);
    }

    /// Retrieves the global language tag for the context.
    ///
    /// **Returns**
    ///
    /// the global language tag.
    pub fn getLanguage(self: *Context) !*pango.Language {
        return c.pango_context_get_language(self) orelse error.NullPointer;
    }

    /// Sets the base direction for the context.
    ///
    /// The base direction is used in applying the Unicode bidirectional
    /// algorithm; if the direction is `pango.Direction` `.Ltr` or `.Rtl`, then
    /// the value will be used as the paragraph direction in the Unicode
    /// bidirectional algorithm. A value of `.WeakLtr` or `Weak.Rtl` is used
    /// only for paragraphs that do not contain any strong characters
    /// themselves.
    ///
    /// **Parameters**
    /// - `direction`: the new base direction.
    pub fn setBaseDir(self: *Context, direction: Direction) void {
        c.pango_context_set_base_dir(self, direction);
    }

    /// Retrieves the base direction for the context.
    ///
    /// See `pango.setBaseDir()`.
    ///
    /// **Returns**
    ///
    /// the base direction for the context.
    pub fn getBaseDir(self: *Context) Direction {
        return c.pango_context_get_base_dir(self);
    }

    /// Sets the base gravity for the context.
    ///
    /// The base gravity is used in laying vertical text out.
    ///
    /// **Parameters**
    /// - `gravity`: the new base gravity
    pub fn setBaseGravity(self: *Context, gravity: pango.Gravity) void {
        c.pango_context_set_base_gravity(self, gravity);
    }

    /// Retrieves the base gravity for the context.
    ///
    /// See `pango.Context.setBaseGravity()`.
    ///
    /// **Returns**
    ///
    /// the base gravity for the context.
    pub fn getBaseGravity(self: *Context) pango.Gravity {
        return c.pango_context_get_base_gravity(self);
    }

    /// Retrieves the gravity for the context.
    ///
    /// This is similar to `pango.Context.getBaseGravity()`, except for when
    /// the base gravity is `pango.Gravity.Auto` for which
    /// `pango.Gravity.getForMatrix()` is used to return the gravity from the
    /// current context matrix.
    ///
    /// **Returns**
    ///
    /// the resolved gravity for the context.
    pub fn getGravity(self: *Context) pango.Gravity {
        return c.pango_context_get_gravity(self);
    }

    /// Sets the gravity hint for the context.
    ///
    /// The gravity hint is used in laying vertical text out, and is only
    /// relevant if gravity of the context as returned by
    /// `pango.Context.getGravity()` is set to `pango.Gravity.East` or
    /// `pango.Gravity.West`.
    ///
    /// **Parameters**
    /// - `hint`: the new gravity hint
    pub fn setGravityHint(self: *Context, hint: pango.GravityHint) void {
        c.pango_context_set_gravity_hint(self, hint);
    }

    /// Retrieves the gravity hint for the context.
    ///
    /// See `pango.Context.setGravityHint()`.
    ///
    /// **Returns**
    ///
    /// the gravity hint for the context.
    pub fn getGravityHint(self: *Context) pango.GravityHint {
        return c.pango_context_get_gravity_hint(self);
    }

    /// Sets the transformation matrix that will be applied when rendering with
    /// this context.
    ///
    /// Note that reported metrics are in the user space coordinates before the
    /// application of the matrix, not device-space coordinates after the
    /// application of the matrix. So, they don’t scale with the matrix, though
    /// they may change slightly for different matrices, depending on how the
    /// text is fit to the pixel grid.
    ///
    /// **Parameters**
    /// - `matrix`: a `pango.Matrix`, or `null` to unset any existing matrix
    /// (no matrix set is the same as setting the identity matrix)
    pub fn setMatrix(self: *Context, matrix: ?*const pango.Matrix) void {
        c.pango_context_set_matrix(self, matrix);
    }

    /// Gets the transformation matrix that will be applied when rendering with
    /// this context.
    ///
    /// See `pango.Context.setMatrix()`.
    ///
    /// **Returns**
    ///
    /// the matrix, or `null` if no matrix has been set (which is the same as
    /// the identity matrix). The returned matrix is owned by Pango and must
    /// not be modified or freed.
    pub fn getMatrix(self: *Context) ?*const pango.Matrix {
        return c.pango_context_get_matrix(self);
    }

    /// Sets whether font rendering with this context should round glyph
    /// positions and widths to integral positions, in device units.
    ///
    /// This is useful when the renderer can’t handle subpixel positioning of
    /// glyphs.
    ///
    /// The default value is to round glyph positions, to remain compatible
    /// with previous Pango behavior.
    ///
    /// **Parameters**
    /// - `round_positions`: whether to round glyph positions
    pub fn setRoundGlyphPositions(self: *Context, round_positions: bool) void {
        c.pango_context_set_round_glyph_positions(self, if (round_positions) 1 else 0);
    }

    /// Returns whether font rendering with this context should round glyph
    /// positions and widths.
    pub fn getRoundGlyphPositions(self: *Context) bool {
        return c.pango_context_get_round_glyph_positions(self) != 0;
    }
};
