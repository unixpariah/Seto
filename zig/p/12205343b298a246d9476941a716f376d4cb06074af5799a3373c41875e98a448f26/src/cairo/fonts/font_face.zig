//! `cairo.FontFace` — Base class for font faces
//!
//! `cairo.FontFace` represents a particular font at a particular weight,
//! slant, and other characteristic but no size, transformation, or size.
//!
//! Font faces are created using *font-backend*-specific constructors,
//! typically of the form cairo_backend_font_face_create(), or implicitly using
//! the toy text API by way of `cairo.Context.selectFontFace()`. The resulting
//! face can be accessed using `cairo.Context.getFontFace()`.
// TODO: fix desc

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const CairoError = cairo.CairoError;
const Status = cairo.Status;
const UserDataKey = cairo.UserDataKey;
const DestroyFn = cairo.DestroyFn;

pub fn Base(comptime Self: type) type {
    return struct {
        /// Increases the reference count on `self` by one. This prevents `self`
        /// from being destroyed until a matching call to `.destroy()` is made.
        ///
        /// Use `cairo.FontFace.getReferenceCount()` to get the number of
        /// references to a `cairo.FontFace`.
        ///
        /// **Returns**
        ///
        /// the referenced `cairo.FontFace`.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-reference)
        pub fn reference(self: *Self) *Self {
            if (safety.tracing) safety.reference(@returnAddress(), self);
            return @ptrCast(c.cairo_font_face_reference(self).?);
        }

        /// Decreases the reference count on `self` by one. If the result is zero,
        /// then `self` and all associated resources are freed. See
        /// `cairo.FontFace.reference()`.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-destroy)
        pub fn destroy(self: *Self) void {
            c.cairo_font_face_destroy(self);
            if (safety.tracing) safety.destroy(self);
        }

        /// Checks whether an error has previously occurred for this font face.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-status)
        pub fn status(self: *Self) Status {
            return c.cairo_font_face_status(self);
        }

        /// This function returns the type of the backend used to create a font
        /// face. See `cairo.FontFace.Type` for available types.
        ///
        /// **Returns**
        ///
        /// the type of `self`.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-get-type)
        pub fn getType(self: *Self) FontFace.Type {
            return c.cairo_font_face_get_type(self);
        }

        /// Returns the current reference count of `self`.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-get-reference-count)
        pub fn getReferenceCount(self: *Self) usize {
            return @intCast(c.cairo_font_face_get_reference_count(self));
        }

        /// Attach user data to `font_face`. To remove user data from a font face,
        /// call this function with the key that was used to set it and `null` for
        /// `data`.
        ///
        /// **Parameters**
        /// - `key`: the address of a `cairo.UserDataKey` to attach the user data
        /// to
        /// - `user_data`: the user data to attach to the font face
        /// - `destroyFn`: a `cairo.DestroyFn` which will be called when the font
        /// face is destroyed or when new user data is attached using the same key.
        ///
        /// The only possible error is `error.OutOfMemory` if a slot could not be
        /// allocated for the user data.
        ///
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-get-user-data)
        pub fn setUserData(self: *Self, key: *const UserDataKey, user_data: ?*anyopaque, destroyFn: DestroyFn) CairoError!void {
            try c.cairo_font_face_set_user_data(self, key, user_data, destroyFn).toErr();
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
        /// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-set-user-data)
        pub fn getUserData(self: *Self, key: *const UserDataKey) ?*anyopaque {
            return c.cairo_font_face_get_user_data(self, key);
        }
    };
}

/// A `cairo.FontFace` specifies all aspects of a font other than the size or
/// font matrix (a font matrix is used to distort a font by shearing it or
/// scaling it unequally in the two directions). A font face can be set on a
/// `cairo.Context` by using `cr.setFontFace()` on it; the size and font
/// matrix are set with `cr.setFontSize()` and `cr.setFontMatrix()`.
///
/// There are various types of font faces, depending on the *font backend* they
/// use. The type of a font face can be queried using `fontFace.getType()`.
///
/// Memory management of `cairo.FontFace` is done with `fontFace.reference()`
/// and `fontFace.destroy()`
///
/// [Link to Cairo documentation](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html#cairo-font-face-t)
pub const FontFace = opaque {
    pub usingnamespace Base(@This());
    /// `cairo.FontFace.Type` is used to describe the type of a given font face
    /// or scaled font. The font types are also known as "font backends" within
    /// cairo.
    ///
    /// The type of a font face is determined by the function used to create
    /// it, which will generally be of the form `cairo_type_font_face_create`.
    /// The font face type can be queried with `fontFace.getType()`.
    ///
    /// The various `cairo.FontFace` functions can be used with a font face of
    /// any type.
    ///
    /// The type of a scaled font is determined by the type of the font face
    /// passed to `cairo_scaled_font_create()`. The scaled font type can be
    /// queried with `cairo_scaled_font_get_type()`.
    ///
    /// The various `cairo.ScaledFont` functions can be used with scaled fonts
    /// of any type, but some font backends also provide type-specific
    /// functions that must only be called with a scaled font of the
    /// appropriate type. These functions have names that begin with
    /// `cairo_type_scaled_font()` such as `cairo_ft_scaled_font_lock_face()`.
    ///
    /// The behavior of calling a type-specific function with a scaled font of
    /// the wrong type is undefined.
    ///
    /// New entries may be added in future versions.
    pub const Type = enum(c_uint) {
        // TODO: fix desc
        /// The font was created using cairo's toy font api
        Toy,
        /// The font is of type FreeType
        Ft,
        /// The font is of type Win32
        Win32,
        /// The font is of type Quartz
        Quartz,
        /// The font was create using cairo's user font api
        User,
    };

    /// Specifies variants of a font face based on their slant.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-font-slant-t)
    pub const FontSlant = enum(c_uint) {
        /// Upright font style
        Normal,
        /// Italic font style
        Italic,
        /// Oblique font style
        Oblique,
    };

    /// Specifies variants of a font face based on their weight.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-text.html#cairo-font-weight-t)
    pub const FontWeight = enum(c_uint) {
        /// Normal font weight
        Normal,
        /// Bold font weight
        Bold,
    };
};
