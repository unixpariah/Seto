const std = @import("std");
const safety = @import("safety");

const pango = @import("../pango.zig");
const c = pango.c;

/// The `pango.AttrType` distinguishes between different types of attributes.
///
/// Along with the predefined values, it is possible to allocate additional
/// values for custom attributes using `pango_attr_type_register()`. The
/// predefined values are given below. The type of structure used to store the
/// attribute is listed in parentheses after the description.
pub const AttrType = enum(c_uint) {
    /// Does not happen.
    Invalid,
    ///
    Language,
    Family,
    Style,
    Weight,
    Variant,
    Stretch,
    Size,
    FontDesc,
    Foreground,
    Background,
    Underline,
    Strikethrough,
    Rise,
    Shape,
    Scale,
    Fallback,
    LetterSpacing,
    UnderlineColor,
    StrikethroughColor,
    AbsoluteSize,
    Gravity,
    GravityHint,
    FontFeatures,
    ForegroundAlpha,
    BackgroundAlpha,
    AllowBreaks,
    Show,
    InsertHyphens,
    Overline,
    OverlineColor,
    LineHeight,
    AbsoluteLineHeight,
    TextTransform,
    Word,
    Sentence,
    BaselineShift,
    FontScale,
};

pub const AttrList = @import("attributes/attr_list.zig").AttrList;

/// The `pango.Attribute` structure represents the common portions of all
/// attributes.
///
/// Particular types of attributes include this structure as their initial
/// portion. The common portion of the attribute holds the range to which the
/// value in the type-specific part of the attribute applies and should be
/// initialized using `pango.Attribute.init()`. By default, an attribute will
/// have an all-inclusive range of [0,`std.math.maxInt(c_uint)`].
pub const Attribute = extern struct {
    /// The class structure holding information about the type of the
    /// attribute.
    klass: *const AttrClass,
    /// The start index of the range (in bytes).
    start_index: c_uint,
    /// End index of the range (in bytes). The character at this index is not
    /// included in the range.
    end_index: c_uint,

    pub fn destroy(self: *Attribute) void {
        c.pango_attribute_destroy(self);
        if (safety.tracing) safety.destroy(self);
    }
};

/// The `pango.AttrClass` structure stores the type and operations for a
/// particular type of attribute.
///
/// The functions in this structure should not be called directly. Instead, one
/// should use the wrapper functions provided for `pango.Attribute`.
pub const AttrClass = extern struct {
    /// The type ID for this attribute.
    type: AttrType,
    copy: ?*const fn ([*c]const Attribute) callconv(.C) [*c]Attribute,
    destroy: ?*const fn ([*c]Attribute) callconv(.C) void,
    equal: ?*const fn ([*c]const Attribute, [*c]const Attribute) callconv(.C) c_int, // bool
};

/// The `pango.AttrShape` structure is used to represent attributes which
/// impose shape restrictions.
pub const AttrShape = extern struct {
    /// The common portion of the attribute.
    attr: Attribute,
    /// The ink rectangle to restrict to.
    ink_rect: pango.Rectangle,
    /// The logical rectangle to restrict to.
    logical_rect: pango.Rectangle,
    /// User data set (see `pango.AttrShape.newWithData()`)
    data: ?*anyopaque,
    /// Copy function for the user data.
    copy_func: pango.AttrDataCopyFunc,
    /// Destroy function for the user data.
    destroy_func: pango.GDestroyNotify,

    /// Create a new shape attribute.
    ///
    /// A shape is used to impose a particular ink and logical rectangle on the
    /// result of shaping a particular glyph. This might be used, for instance,
    /// for embedding a picture or a widget inside a `pango.Layout`.
    ///
    /// **Parameters**
    /// - `ink_rect`: ink rectangle to assign to each character
    /// - `logical_rect`: logical rectangle to assign to each character
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.Attribute`.
    ///
    /// **NOTE**: The caller owns the created `pango.Attribute` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr = try pango.AttrShape.new();
    /// defer attr.destroy();
    /// ```
    pub fn new(ink_rect: *const pango.Rectangle, logical_rect: *const pango.Rectangle) !*Attribute {
        const ptr = c.pango_attr_shape_new(ink_rect, logical_rect) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Creates a new shape attribute.
    ///
    /// Like `pango.AttrShape.new()`, but a user data pointer is also provided;
    /// this pointer can be accessed when later rendering the glyph.
    ///
    /// **Parameters**
    /// - `ink_rect`: ink rectangle to assign to each character
    /// - `logical_rect`: logical rectangle to assign to each character
    /// - `data`: user data pointer
    /// - `copy_func`: function to copy `data` when the attribute is copied; If
    /// `null`, data is simply copied as a pointer
    /// - `destroy_func`: function to free `data` when the attribute is freed
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.Attribute`.
    ///
    /// **NOTE**: The caller owns the created `pango.Attribute` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr = try pango.AttrShape.newWithData(...);
    /// defer attr.destroy();
    /// ```
    pub fn newWithData(ink_rect: *const pango.Rectangle, logical_rect: *const pango.Rectangle, data: ?*anyopaque, copy_func: pango.AttrDataCopyFunc, destroy_func: pango.GDestroyNotify) !*Attribute {
        // TODO: fix example
        const ptr = c.pango_attr_shape_new_with_data(ink_rect, logical_rect, data, copy_func, destroy_func) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }
};
