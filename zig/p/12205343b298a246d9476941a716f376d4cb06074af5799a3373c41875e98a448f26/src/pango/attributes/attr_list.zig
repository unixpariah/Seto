const std = @import("std");
const safety = @import("safety");

const pango = @import("../../pango.zig");
const c = pango.c;

/// A `pango.AttrList` represents a list of attributes that apply to a section
/// of text.
///
/// The attributes in a `pango.AttrList` are, in general, allowed to overlap in
/// an arbitrary fashion. However, if the attributes are manipulated only
/// through `pango.AttrList.change()`, the overlap between properties will meet
/// stricter criteria.
///
/// Since the `pango.AttrList` structure is stored as a linear list, it is not
/// suitable for storing attributes for large amounts of text. In general, you
/// should not use a single `pango.AttrList` for more than one paragraph of
/// text.
pub const AttrList = opaque {
    /// Create a new empty attribute list with a reference count of one.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.AttrList`.
    ///
    /// **NOTE**: The caller owns the created `pango.AttrList` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr_list = try pango.AttrList.new();
    /// defer attr_list.destroy();
    /// ```
    pub fn create() !*AttrList {
        const ptr = c.pango_attr_list_new() orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Deserializes a `pango.AttrList` from a string.
    ///
    /// This is the counterpart to `pango.AttrList.toString()`. See that
    /// functions for details about the format.
    ///
    /// **Returns**
    ///
    /// a new `pango.AttrList`.
    ///
    /// **NOTE**: The caller owns the created `pango.AttrList` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr_list = try pango.AttrList.fromString("0 200 font-desc \"Sans 10\"");
    /// defer attr_list.destroy();
    /// ```
    pub fn fromString(text: [:0]const u8) !*AttrList {
        const ptr = c.pango_attr_list_from_string(text) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Increase the reference count of the given attribute list by one.
    ///
    /// **Return**
    ///
    /// the attribute list passed in.
    pub fn reference(self: *AttrList) *AttrList {
        if (safety.tracing) safety.reference(@returnAddress(), self);
        return c.pango_attr_list_ref(self).?;
    }

    /// Decrease the reference count of the given attribute list by one.
    ///
    /// If the result is zero, free the attribute list and the attributes it
    /// contains.
    pub fn destroy(self: *AttrList) void {
        c.pango_attr_list_unref(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Copy `self` and return an identical new list.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.AttrList`.
    ///
    /// **NOTE**: The caller owns the created `pango.AttrList` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr_list = try another.copy();
    /// defer attr_list.destroy();
    /// ```
    pub fn copy(self: *AttrList) !*AttrList {
        const ptr = c.pango_attr_list_copy(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Insert the given attribute into the `pango.AttrList`.
    ///
    /// It will be inserted after all other attributes with a matching
    /// `start_index`.
    ///
    /// **Parameters**
    /// - `attr`: the attribute to insert
    pub fn insert(self: *AttrList, attr: *pango.Attribute) void {
        c.pango_attr_list_insert(self, attr);
        if (safety.tracing) safety.destroy(attr);
    }

    /// Insert the given attribute into the `pango.AttrList`.
    ///
    /// It will be inserted before all other attributes with a matching
    /// `start_index`.
    ///
    /// **Parameters**
    /// - `attr`: the attribute to insert
    pub fn insertBefore(self: *AttrList, attr: *pango.Attribute) void {
        c.pango_attr_list_insert_before(self, attr);
        if (safety.tracing) safety.destroy(attr);
    }

    /// Insert the given attribute into the `pango.AttrList`.
    ///
    /// It will replace any attributes of the same type on that segment and be
    /// merged with any adjoining attributes that are identical.
    ///
    /// This function is slower than `pango.AttrList.insert()` for creating an
    /// attribute list in order (potentially much slower for large lists).
    /// However, `pango.AttrList.insert()` is not suitable for continually
    /// changing a set of attributes since it never removes or combines
    /// existing attributes.
    ///
    /// **Parameters**
    /// - `attr`: the attribute to insert
    pub fn change(self: *AttrList, attr: *pango.Attribute) void {
        c.pango_attr_list_change(self, attr);
        if (safety.tracing) safety.destroy(attr);
    }

    /// This function opens up a hole in `self`, fills it in with attributes
    /// from the left, and then merges `other` on top of the hole.
    ///
    /// This operation is equivalent to stretching every attribute that applies
    /// at position `pos` in `self` by an amount `len`, and then calling
    /// `pango.AttrList.change()` with a copy of each attribute in other in
    /// sequence (offset in position by `pos`, and limited in length to `len`).
    ///
    /// This operation proves useful for, for instance, inserting a pre-edit
    /// string in the middle of an edit buffer.
    ///
    /// For backwards compatibility, the function behaves differently when
    /// `len` is 0. In this case, the attributes from `other` are not imited to
    /// `len`, and are just overlayed on top of `self`.
    ///
    /// This mode is useful for merging two lists of attributes together.
    ///
    /// **Parameters**
    /// - `other`: another `pango.AttrList`
    /// - `pos`: the position in `self` at which to insert other
    /// - `len`: the length of the spliced segment (note that this must be
    /// specified since the attributes in `other` may only be present at some
    /// subsection of this range)
    pub fn splice(self: *AttrList, other: *AttrList, pos: u32, len: u32) void {
        c.pango_attr_list_splice(self, other, @intCast(pos), @intCast(len));
    }

    /// Update indices of attributes in `self` for a change in the text they
    /// refer to.
    ///
    /// The change that this function applies is `removing` remove bytes at
    /// position `pos` and inserting `add` bytes instead.
    ///
    /// Attributes that fall entirely in the (`pos`, `pos` + `remove`) range
    /// are removed.
    ///
    /// Attributes that start or end inside the (`pos`, `pos` + `remove`) range
    /// are shortened to reflect the removal.
    ///
    /// Attributes start and end positions are updated if they are behind `pos`
    /// + `remove`.
    ///
    /// **Parameters**
    /// - `pos`: the position of the change
    /// - `remove`: the number of removed bytes
    /// - `add`: the number of added bytes
    pub fn update(self: *AttrList, pos: i32, remove: i32, add: i32) void {
        c.pango_attr_list_update(self, pos, remove, add);
    }

    /// Checks whether `self` and `other` contain the same attributes and
    /// whether those attributes apply to the same ranges.
    ///
    /// Beware that this will return wrong values if any list contains
    /// duplicates.
    ///
    /// **Parameters**
    /// - `other`: the other `pango.AttrList`
    ///
    /// **Returns**
    ///
    /// `true` if the lists are equal, `false` if they aren’t.
    pub fn equal(self: *AttrList, other: *AttrList) bool {
        return c.pango_attr_list_equal(self, other) != 0;
    }

    /// Given a `pango.AttrList` and callback function, removes any elements of
    /// list for which func returns `true` and inserts them into a new list.
    ///
    /// **Parameters**
    /// - `func`: callback function; returns `1` if an attribute should be
    /// filtered out
    /// - `data`: data to be passed to `func`
    ///
    /// **Returns**
    ///
    /// the new `pango.AttrList` or fails if no attributes of the given types
    /// were found.
    ///
    /// **NOTE**: The caller owns the created `pango.AttrList` and should call
    /// `.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const attr_list = try another.filter(...);
    /// defer attr_list.destroy();
    /// ```
    pub fn filter(self: *AttrList, func: pango.AttrFilterFunc, data: ?*anyopaque) !*AttrList {
        // TODO: fix example
        const ptr = c.pango_attr_list_filter(self, func, data) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Serializes a `pango.AttrList` to a string.
    ///
    /// In the resulting string, serialized attributes are separated by
    /// newlines or commas. Individual attributes are serialized to a string of
    /// the form
    /// ```code
    /// START END TYPE VALUE
    /// ```
    /// Where START and END are the indices (with -1 being accepted in place of MAXUINT), TYPE is the nickname of the attribute value type, e.g. weight or stretch, and the value is serialized according to its type:
    ///
    /// **Returns**
    ///
    /// a newly allocated string.
    ///
    /// **NOTE**: The caller owns the created string and should call
    /// `pango.free()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const str = try attr_list.toString();
    /// defer pango.free(str);
    /// ```
    pub fn toString(self: *AttrList) ![:0]const u8 {
        const ptr = c.pango_attr_list_to_string(self);
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return std.mem.span(ptr);
    }
};
