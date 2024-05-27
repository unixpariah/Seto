//! Regions — Representing a pixel-aligned area
//!
//! Regions are a simple graphical data type representing an area of integer-aligned
//! rectangles. They are often used on raster surfaces to track areas of interest,
//! such as change or clip areas.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html)

const std = @import("std");

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Context = cairo.Context;
const RectangleInt = cairo.RectangleInt;

const Status = cairo.Status;
const CairoError = cairo.CairoError;

/// A `cairo.Region` represents a set of integer-aligned rectangles.
///
/// It allows set-theoretical operations like `region.union()` and
/// `region.intersect()` to be performed on them.
///
/// Memory management of `cairo.Region` is done with `region.reference()` and
/// `region.destroy()`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-t)
pub const Region = opaque {
    /// Used as the return value for `cairo.Region.containsRectangle()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-overlap-t)
    pub const Overlap = enum(c_uint) {
        /// The contents are entirely inside the region
        In,
        /// The contents are entirely outside the region
        Out,
        /// The contents are partially inside and partially outside the region
        Part,
    };

    /// Allocates a new empty region object.
    ///
    /// **Returns**
    ///
    /// a newly allocated `cairo.Region`. **NOTE**: The caller owns the created
    /// region and should call `region.destroy()` when done with it. You can
    /// use idiomatic Zig pattern with `defer`:
    /// ```zig
    /// const region = try cairo.Region.create();
    /// defer region.destroy();
    /// ```
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-create)
    pub fn create() CairoError!*Region {
        const region = c.cairo_region_create().?;
        try region.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), region);
        return region;
    }

    /// Allocates a new region object containing `rectangle`.
    ///
    /// **Parameters**
    /// - `rectangle`: a `cairo.RectangleInt`
    ///
    /// **Returns**
    ///
    /// a newly allocated `cairo.Region`. **NOTE**: The caller owns the created
    /// region and should call `region.destroy()` when done with it. You can
    /// use idiomatic Zig pattern with `defer`:
    /// ```zig
    /// const rect = RectangleInt.init(.{ 0, 0, 100, 100 });
    /// const region = try cairo.Region.createRectangle(&rect);
    /// defer region.destroy();
    /// ```
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-create-rectangle)
    pub fn createRectangle(rectangle: *const RectangleInt) CairoError!*Region {
        const region = c.cairo_region_create_rectangle(rectangle).?;
        try region.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), region);
        return region;
    }

    /// Allocates a new region object containing the union of all given `rects`.
    ///
    /// **Parameters**
    /// - `rects`: a slice of rectangles
    ///
    /// **Returns**
    ///
    /// a newly allocated `cairo.Region`. **NOTE**: The caller owns the created
    /// region and should call `region.destroy()` when done with it. You can
    /// use idiomatic Zig pattern with `defer`:
    /// ```zig
    /// const region = try createRectangles(&.{
    ///     RectangleInt.init(.{ 20, 10, 50, 60 }),
    ///     RectangleInt.init(.{ 10, 20, 50, 40 }),
    /// });
    /// defer region.destroy();
    /// ```
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-create-rectangles)
    pub fn createRectangles(rects: []const RectangleInt) CairoError!*Region {
        const region = c.cairo_region_create_rectangles(rects.ptr, @intCast(rects.len)).?;
        try region.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), region);
        return region;
    }

    /// Allocates a new region object copying the area from `self`.
    ///
    /// **Returns**
    ///
    /// a newly allocated `cairo.Region`. **NOTE**: The caller owns the created
    /// region and should call `region.destroy()` when done with it. You can
    /// use idiomatic Zig pattern with `defer`:
    /// ```zig
    /// const regOriginal = try cairo.Region.create();
    /// defer regOriginal.destroy();
    ///
    /// const regCopy = try regOriginal.copy();
    /// defer regCopy.destroy();
    /// ```
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-copy)
    pub fn copy(self: *const Region) CairoError!*Region {
        const region = c.cairo_region_copy(self).?;
        try region.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), region);
        return region;
    }

    /// Increases the reference count on `self` by one. This prevents region
    /// from being destroyed until a matching call to `region.destroy()` is
    /// made.
    ///
    /// **Returns**
    ///
    /// the referenced `cairo.Region`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-reference)
    pub fn reference(self: *Region) *Region {
        if (safety.tracing) safety.reference(@returnAddress(), self);
        return c.cairo_region_reference(self).?;
    }

    /// Destroys a `cairo.Region` object created with `Region.create()`,
    /// `Region.copy()`, or `Region.createRectangle()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-destroy)
    pub fn destroy(self: *Region) void {
        c.cairo_region_destroy(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Checks whether an error has previous occurred for this region object.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-status)
    pub inline fn status(self: *const Region) Status {
        return c.cairo_region_status(self);
    }

    /// Gets the bounding rectangle of `self` region as a `cairo.RectangleInt`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-get-extents)
    pub inline fn getExtents(self: *const Region) RectangleInt {
        var rect: RectangleInt = undefined;
        c.cairo_region_get_extents(self, &rect);
        return rect;
    }

    /// Returns the number of rectangles contained in `self`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-num-rectangles)
    pub fn numRectangles(self: *const Region) usize {
        return @intCast(c.cairo_region_num_rectangles(self));
    }

    /// Returns the `nth` rectangle from the `self` region
    ///
    /// **Parameters**
    ///
    /// - `nth`: a number indicating which rectangle should be returned
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-get-rectangle)
    pub inline fn getRectangle(self: *const Region, nth: usize) RectangleInt {
        var rect: RectangleInt = undefined;
        c.cairo_region_get_rectangle(self, @intCast(nth), &rect);
        return rect;
    }

    /// Checks whether `self` region is empty.
    ///
    /// **Returns**
    ///
    /// `true` if region is empty, `false` if it isn't.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-is-empty)
    pub fn isEmpty(self: *const Region) bool {
        return c.cairo_region_is_empty(self) != 0;
    }

    /// Checks whether `(x, y)` is contained in region.
    ///
    /// **Parameters**
    /// - `x`: the x coordinate of a point
    /// - `y`: the y coordinate of a point
    ///
    /// **Returns**
    ///
    /// `true` if `(x, y)` is contained in region, `false` if it is not.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-contains-point)
    pub fn containsPoint(self: *const Region, x: i32, y: i32) bool {
        const result = c.cairo_region_contains_point(self, @intCast(x), @intCast(y));
        return result != 0;
    }

    /// Checks whether `rectangle` is inside, outside or partially contained in
    /// `self` region
    ///
    /// **Returns**
    ///
    /// `cairo.Region.Overlap.In` if `rectangle` is entirely inside `self`,
    /// `.Out` if `rectangle` is entirely outside `self`, or `.Part` if
    /// `rectangle` is partially inside and partially outside `self`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-contains-rectangle)
    pub fn containsRectangle(self: *const Region, rectangle: *const RectangleInt) Overlap {
        return c.cairo_region_contains_rectangle(self, rectangle);
    }

    /// Compares whether `self` region is equivalent to `other`.
    ///
    /// **Returns**
    /// `true` if both regions contained the same coverage, `false` if it is
    /// not or any region is in an error status.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-equal)
    pub fn equal(self: *const Region, other: *const Region) bool {
        return c.cairo_region_equal(self, other) != 0;
    }

    /// Translates `self` region by `(dx, dy)`.
    ///
    /// **Parameters**
    /// - `dx`: Amount to translate in the x direction
    /// - `dy`: Amount to translate in the y direction
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-translate)
    pub fn translate(self: *Region, dx: i32, dy: i32) void {
        c.cairo_region_translate(self, @intCast(dx), @intCast(dy));
    }

    /// Computes the intersection of `self` region with `other` and places the
    /// result in `self`.
    ///
    /// **Parameters**
    /// - `other`: a `cairo.Region`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-intersect)
    pub fn intersect(self: *Region, other: *const Region) CairoError!void {
        try c.cairo_region_intersect(self, other).toErr();
    }

    /// Computes the intersection of `self` region with `rectangle` and places
    /// the result in `self`.
    ///
    /// **Parameters**
    /// - `rectangle`: a `cairo.RectangleInt`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-intersect-rectangle)
    pub fn intersectRectangle(self: *Region, rectangle: *const RectangleInt) CairoError!void {
        try c.cairo_region_intersect_rectangle(self, rectangle).toErr();
    }

    /// Subtracts `other` from `self` region and places the result in `self`
    ///
    /// **Parameters**
    /// - `other`: a `cairo.Region`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-subtract)
    pub fn subtract(self: *Region, other: *const Region) CairoError!void {
        try c.cairo_region_subtract(self, other).toErr();
    }

    /// Subtracts `rectangle` from `self` region and places the result in
    /// `self`
    ///
    /// **Parameters**
    /// - `rectangle`: a `cairo.RectangleInt`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-subtract-rectangle)
    pub fn subtractRectangle(self: *Region, rectangle: *const RectangleInt) CairoError!void {
        try c.cairo_region_subtract_rectangle(self, rectangle).toErr();
    }

    /// Computes the union of `self` region with `other` and places the result
    /// in `self`
    ///
    /// **Parameters**
    /// - `other`: a `cairo.Region`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-union)
    pub fn unionSimple(self: *Region, other: *const Region) CairoError!void {
        try c.cairo_region_union(self, other).toErr();
    }

    /// Computes the union of `self` region with `rectangle` and places the
    /// result in `self`
    ///
    /// **Parameters**
    /// - `rectangle`: a `cairo.RectangleInt`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-union-rectangle)
    pub fn unionRectangle(self: *Region, rectangle: *const RectangleInt) CairoError!void {
        try c.cairo_region_union_rectangle(self, rectangle).toErr();
    }

    /// Computes the exclusive difference of `self` region with `other` and
    /// places the result in `self`. That is, `self` will be set to contain all
    /// areas that are either in `self` or in `other`, but not in both.
    ///
    /// **Parameters**
    /// - `other`: a `cairo.Region`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-xor)
    pub fn xor(self: *Region, other: *const Region) CairoError!void {
        try c.cairo_region_xor(self, other).toErr();
    }

    /// Computes the exclusive difference of `self` region with `rectangle` and
    /// places the result in `self`. That is, `self` will be set to contain all
    /// areas that are either in `self` or in `rectangle`, but not in both.
    ///
    /// **Parameters**
    /// - `rectangle`: a `cairo.RectangleInt`
    ///
    /// The only possible error is `error.OutOfMemory`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Regions.html#cairo-region-xor-rectangle)
    pub fn xorRectangle(self: *Region, rectangle: *const RectangleInt) CairoError!void {
        try c.cairo_region_xor_rectangle(self, rectangle).toErr();
    }
};
