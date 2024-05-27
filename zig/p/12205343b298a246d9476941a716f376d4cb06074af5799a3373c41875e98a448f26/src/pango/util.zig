const safety = @import("safety");
const pango = @import("../pango.zig");
const c = pango.c;

/// The `pango.Rectangle` structure represents a rectangle.
///
/// `pango.Rectangle` is frequently used to represent the logical or ink
/// extents of a single glyph or section of text. (See, for instance,
/// `pango.Font.getGlyphExtents()`.)
pub const Rectangle = extern struct {
    /// X coordinate of the left side of the rectangle.
    x: c_int,
    /// Y coordinate of the the top side of the rectangle.
    y: c_int,
    /// Width of the rectangle.
    width: c_int,
    /// Height of the rectangle.
    height: c_int,

    pub fn init(x: c_int, y: c_int, width: c_int, height: c_int) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
};

pub fn free(memory: anytype) void {
    const info = @typeInfo(@TypeOf(memory));
    switch (info) {
        .Pointer => c.g_free(@ptrCast(memory)),
        else => @compileError("wrong type"),
    }
    if (safety.tracing) safety.destroy(@ptrCast(memory));
}

/// Type of a function that can duplicate user data for an attribute.
///
/// **Parameters**
/// - `user_data`: user data to copy
///
/// **Returns**
///
/// new copy of `user_data`.
pub const AttrDataCopyFunc = ?*const fn (?*const anyopaque) callconv(.C) ?*anyopaque;
// TODO: clarify ownership

/// Specifies the type of function which is called when a data element is
/// destroyed. It is passed the pointer to the data element and should free any
/// memory and resources allocated for it.
pub const GDestroyNotify = ?*const fn (?*anyopaque) callconv(.C) void;

pub const AttrFilterFunc = ?*const fn ([*c]pango.Attribute, ?*anyopaque) callconv(.C) c_int; // bool
