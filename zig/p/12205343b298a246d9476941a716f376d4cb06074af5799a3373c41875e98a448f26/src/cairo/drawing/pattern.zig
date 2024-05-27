//! `cairo.Pattern` — Sources for drawing
//!
//! `cairo.Pattern` is the paint with which cairo draws. The primary use of
//! patterns is as the source for all cairo drawing operations, although they
//! can also be used as masks, that is, as the brush too.
//!
//! A cairo pattern is created by using one of the many constructors, of the
//! form `cairo.Pattern.create*Type*()` or implicitly through
//! `cr.setSource*Type*()` functions.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html)

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Content = cairo.Content;
const Status = cairo.Status;
const CairoError = cairo.CairoError;

const Surface = cairo.Surface;
const Path = cairo.Path;

const RectangleInt = cairo.RectangleInt;
const Matrix = cairo.Matrix;
const UserDataKey = cairo.UserDataKey;
const DestroyFn = cairo.DestroyFn;
const Point = cairo.Point;

fn Mixin(comptime Self: type) type {
    return struct {
        /// Casts a pointer to the particular pattern into base
        /// `*cairo.Pattern` object.
        pub fn asPattern(self: *Self) *Pattern {
            return @ptrCast(self);
        }

        /// Sets the mode to be used for drawing outside the area of a pattern.
        /// See `cairo.Pattern.Extend` for details on the semantics of each
        /// extend strategy.
        ///
        /// The default extend mode is `.None` for surface patterns and `.Pad` for
        /// gradient patterns.
        ///
        /// **Parameters**
        /// - `extend`: a `cairo.Pattern.Extend` describing how the area
        /// outside of the pattern will be drawn
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-extend)
        pub fn setExtend(self: *Self, extend: Pattern.Extend) void {
            c.cairo_pattern_set_extend(self, extend);
        }

        /// Gets the current extend mode for a pattern. See
        /// `cairo.Pattern.Extend` for details on the semantics of each extend
        /// strategy.
        ///
        /// **Returns**
        ///
        /// the current extend strategy used for drawing the pattern.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-extend)
        pub fn getExtend(self: *Self) Pattern.Extend {
            return c.cairo_pattern_get_extend(self);
        }

        /// Sets the pattern's transformation matrix to `matrix`. This matrix is a
        /// transformation from user space to pattern space.
        ///
        /// When a pattern is first created it always has the identity matrix for
        /// its transformation matrix, which means that pattern space is initially
        /// identical to user space.
        ///
        /// Important: Please note that the direction of this transformation matrix
        /// is from user space to pattern space. This means that if you imagine the
        /// flow from a pattern to user space (and on to device space), then
        /// coordinates in that flow will be transformed by the inverse of the
        /// pattern matrix.
        ///
        /// For example, if you want to make a pattern appear twice as large as it
        /// does by default the correct code to use is:
        /// ```zig
        /// var matrix: cairo.Matrix = undefined;
        /// matrix.initScale(0.5, 0.5);
        /// pattern.setMatrix(&matrix);
        /// ```
        /// Meanwhile, using values of 2.0 rather than 0.5 in the code above would
        /// cause the pattern to appear at half of its default size.
        ///
        /// Also, please note the discussion of the user-space locking semantics of
        /// `cairo.Context.setSource()`.
        ///
        /// **Parameters**
        /// - `matrix`: a `cairo.Matrix`
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-matrix)
        pub fn setMatrix(self: *Self, matrix: *const Matrix) void {
            // TODO: check if undefined matrix cause problems
            c.cairo_pattern_set_matrix(self, matrix);
        }

        /// Stores the pattern's transformation matrix into `matrix`.
        ///
        /// **Parameters**
        /// - `matrix`: return value for the matrix
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-matrix)
        pub fn getMatrix(self: *Self, matrix: *Matrix) void {
            c.cairo_pattern_get_matrix(self, matrix);
        }

        /// Increases the reference count on pattern by one. This prevents pattern
        /// from being destroyed until a matching call to `pattern.destroy()` is
        /// made.
        ///
        /// Use `pattern.getReferenceCount()` to get the number of references to a
        /// `cairo.Pattern`.
        ///
        /// **Returns**
        ///
        /// the referenced `cairo.Pattern`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-reference)
        pub fn reference(self: *Self) *Self {
            if (safety.tracing) safety.reference(@returnAddress(), self);
            return @ptrCast(c.cairo_pattern_reference(self).?);
        }

        /// Decreases the reference count on pattern by one. If the result is zero,
        /// then pattern and all associated resources are freed. See
        /// `cairo.Pattern.reference()`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-destroy)
        pub fn destroy(self: *Self) void {
            if (safety.tracing) safety.destroy(self);
            return c.cairo_pattern_destroy(self);
        }

        /// Checks whether an error has previously occurred for this pattern.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-status)
        pub fn status(self: *Self) Status {
            return c.cairo_pattern_status(self);
        }

        /// Get the pattern's type. See `cairo.Pattern.Type` for available
        /// types.
        ///
        /// **Returns**
        ///
        /// the type of `self`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-type)
        pub fn getType(self: *Self) Pattern.Type {
            return c.cairo_pattern_get_type(self);
        }

        /// Returns the current reference count of `pattern`.
        ///
        /// **Returns**
        ///
        /// the current reference count of `self`. If the object is a nil object, 0
        /// will be returned.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-reference-count)
        pub fn getReferenceCount(self: *Self) usize {
            return @intCast(c.cairo_pattern_get_reference_count(self));
        }

        /// Attach user data to `pattern`. To remove user data from a surface, call
        /// this function with the key that was used to set it and `null` for
        /// `data`.
        ///
        /// **Parameters**
        /// - `key`: the address of a `cairo.UserDataKey` to attach the user data
        /// to
        /// - `user_data`: the user data to attach to the `cairo.Pattern`
        /// - `destroyFn`: a `cairo.DestroyFn` which will be called when the
        /// `cairo.Context` is destroyed or when new user data is attached using
        /// the same key.
        ///
        /// Possible error is `error.OutOfMemory` if a slot could not be allocated
        /// for the user data.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-user-data)
        pub fn setUserData(self: *Self, key: *const UserDataKey, user_data: ?*anyopaque, destroyFn: DestroyFn) CairoError!void {
            return c.cairo_pattern_set_user_data(self, key, user_data, destroyFn).toErr();
        }

        /// Return user data previously attached to `pattern` using the specified
        /// key. If no user data has been attached with the given key this function
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
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-user-data)
        pub fn getUserData(self: *Self, key: *const UserDataKey) ?*anyopaque {
            return c.cairo_pattern_get_user_data(self, key);
        }
    };
}

/// A `cairo.Pattern` represents a source when drawing onto a surface. There
/// are different subtypes of `cairo.Pattern`, for different types of sources;
/// for example, `cairo.SolidPattern.createRgb()` creates a pattern for a solid
/// opaque color.
///
/// **IMPORTANT**: you should **NOT** create pointers to this type manually.
/// Use `.asPattern()` on a pattern created with
/// `cairo.*Something*Pattern.create()`. Casting `*cairo.Pattern` into anything
/// other than the type it had before `.asPattern()` is an **UNDEFINED
/// BEHAVIOR**.
///
/// Other than various `cairo.Pattern.create*Type*()` functions, some of the
/// pattern types can be implicitly created using various
/// `cr.setSource*Type*()` functions; for example `cr.setSourceRgb()`.
///
/// The type of a pattern can be queried with `pattern.getType()`.
///
/// Memory management of `cairo.Pattern` is done with `pattern.reference()` and
/// `pattern.destroy()`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-t)
pub const Pattern = opaque {
    pub usingnamespace Mixin(@This());

    /// `cairo.Pattern.Type` is used to describe the type of a given pattern.
    ///
    /// The type of a pattern is determined by the function used to create it.
    /// The `cairo.Pattern.createRgb()` and `cairo.Pattern.createRgba()`
    /// functions create SOLID patterns. The remaining cairo.Pattern.create
    /// functions map to pattern types in obvious ways.
    ///
    /// The pattern type can be queried with `pattern.getType()`
    ///
    /// Most `cairo.Pattern` functions can be called with a pattern of any
    /// type, (though trying to change the extend or filter for a solid pattern
    /// will have no effect). A notable exception is
    /// `pattern.addColorStopRgb()` and `pattern.addColorStopRgba()` which must
    /// only be called with gradient patterns (either `.Linear` or `.Radial`).
    /// Otherwise the pattern will be shutdown and put into an error state.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-type-t)
    pub const Type = enum(c_uint) {
        // TODO: fix desc
        /// The pattern is a solid (uniform) color. It may be opaque or
        /// translucent.
        Solid,
        /// The pattern is a based on a surface (an image).
        Surface,
        /// The pattern is a linear gradient.
        Linear,
        /// The pattern is a radial gradient.
        Radial,
        /// The pattern is a mesh.
        Mesh,
        /// The pattern is a user pattern providing raster data.
        RasterSource,
    };

    /// `cairo.Pattern.Extend` is used to describe how pattern color/alpha will be
    /// determined for areas "outside" the pattern's natural area, (for example,
    /// outside the surface bounds or outside the gradient geometry).
    ///
    /// Mesh patterns are not affected by the extend mode.
    ///
    /// The default extend mode is `.None` for surface patterns and `.Pad` for
    /// gradient patterns.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-extend-t)
    pub const Extend = enum(c_uint) {
        /// pixels outside of the source pattern are fully transparent
        None,
        /// the pattern is tiled by repeating
        Repeat,
        /// the pattern is tiled by reflecting at the edges
        Reflect,
        /// pixels outside of the pattern copy the closest pixel from the source
        Pad,
    };

    /// `cairo.Pattern.Filter` is used to indicate what filtering should be
    /// applied when reading pixel values from patterns. See
    /// `cairo.Pattern.setFilter()` for indicating the desired filter to be
    /// used with a particular pattern.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-filter-t)
    pub const Filter = enum(c_uint) {
        /// A high-performance filter, with quality similar to `.Nearest`
        Fast,
        /// A reasonable-performance filter, with quality similar to `.Bilinear`
        Good,
        /// The highest-quality available, performance may not be suitable for
        /// interactive use
        Best,
        /// Nearest-neighbor filtering
        Nearest,
        /// Linear interpolation in two dimensions
        Bilinear,
        /// This filter value is currently unimplemented, and should not be used in
        /// current code
        Gaussian,
    };
};

pub const SolidPattern = opaque {
    pub usingnamespace Mixin(@This());

    /// Creates a new `cairo.SolidPattern` corresponding to an opaque color.
    /// The color components are floating point numbers in the range 0 to 1. If
    /// the values passed in are outside that range, they will be clamped.
    ///
    /// **Parameters**
    /// `red`: red component of the color
    /// `green`: green component of the color
    /// `blue`: blue component of the color
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.SolidPattern` if successful, or an error in
    /// case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.SolidPattern.createRgb(0.3, 0.6, 0.9);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-rgb)
    pub fn createRgb(red: f64, green: f64, blue: f64) CairoError!*SolidPattern {
        const pattern = c.cairo_pattern_create_rgb(red, green, blue).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Creates a new `cairo.SolidPattern` corresponding to an translucent
    /// color. The color components are floating point numbers in the range 0
    /// to 1. If the values passed in are outside that range, they will be
    /// clamped.
    ///
    /// **Parameters**
    /// `red`: red component of the color
    /// `green`: green component of the color
    /// `blue`: blue component of the color
    /// `alpha`: alpha component of the color
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.SolidPattern` if successful, or an error in
    /// case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.SolidPattern.createRgba(0.3, 0.6, 0.9, 0.5);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-rgba)
    pub fn createRgba(red: f64, green: f64, blue: f64, alpha: f64) CairoError!*SolidPattern {
        const pattern = c.cairo_pattern_create_rgba(red, green, blue, alpha).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Gets the solid color for a solid color pattern.
    ///
    /// **Parameters**
    /// - `red`: return value for red component of the color or `null`
    /// - `green`: return value for green component of the color or `null`
    /// - `blue`: return value for blue component of the color or `null`
    /// - `alpha`: return value for alpha component of the color or `null`
    ///
    /// The only possible error is `error.PatternTypeMismatch`, you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-rgba)
    pub fn getRgba(self: *SolidPattern, red: ?*f64, green: ?*f64, blue: ?*f64, alpha: ?*f64) CairoError!void {
        try c.cairo_pattern_get_rgba(self, red, green, blue, alpha).toErr();
    }
};

pub const SurfacePattern = opaque {
    pub usingnamespace Mixin(@This());

    /// Create a new `cairo.SurfacePattern` for the given surface.
    ///
    /// **Parameters**
    ///
    /// - `surface`: the surface
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.SurfacePattern` if successful, or an error in
    /// case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.SurfacePattern.createFor(surface);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-for-surface)
    pub fn createFor(surface: *Surface) CairoError!*SurfacePattern {
        const pattern = c.cairo_pattern_create_for_surface(surface).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Gets the surface of a surface pattern. The reference returned in
    /// `surface` is owned by the pattern; the caller should call
    /// `surface.reference()` if the surface is to be retained.
    ///
    /// The only possible error is `error.PatternTypeMismatch`, you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-surface)
    pub fn getSurface(self: *SurfacePattern) CairoError!*Surface {
        var surface: ?*Surface = undefined;
        try c.cairo_pattern_get_surface(self, &surface).toErr();
        return surface.?;
    }

    /// Sets the filter to be used for resizing when using this pattern. See
    /// `cairo.Pattern.Filter` for details on each filter.
    ///
    /// >Note that you might want to control filtering even when you do not
    /// have an explicit `cairo.Pattern` object, (for example when using
    /// `cr.setSourceSurface()`). In these cases, it is convenient to use
    /// `cr.getSource()` to get access to the pattern that cairo creates
    /// implicitly. For example:
    /// ```zig
    /// cr.setSourceSurface(image, x, y);
    /// Pattern.setFilter(cr.getSource(), .Nearest);
    /// ```
    ///
    /// **Parameters**
    /// - `filter`: a `cairo.Pattern.Filter` describing the filter to use for
    /// resizing the pattern
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-filter)
    pub fn setFilter(self: *SurfacePattern, filter: Pattern.Filter) void {
        c.cairo_pattern_set_filter(self, filter);
    }

    /// Gets the current filter for a pattern. See `cairo.Pattern.Filter` for
    /// details on each filter.
    ///
    /// **Returns**
    ///
    /// the current filter used for resizing the pattern.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-filter)
    pub fn getFilter(self: *SurfacePattern) Pattern.Filter {
        return c.cairo_pattern_get_filter(self);
    }
};

fn Gradient(comptime Self: type) type {
    return struct {
        pub usingnamespace Mixin(Self);

        /// Adds an opaque color stop to a gradient pattern. The offset
        /// specifies the location along the gradient's control vector. For
        /// example, a linear gradient's control vector is from (x0,y0) to
        /// (x1,y1) while a radial gradient's control vector is from any point
        /// on the start circle to the corresponding point on the end circle.
        ///
        /// The color is specified in the same way as in `cr.setSourceRgb()`.
        ///
        /// If two (or more) stops are specified with identical offset values,
        /// they will be sorted according to the order in which the stops are
        /// added, (stops added earlier will compare less than stops added
        /// later). This can be useful for reliably making sharp color
        /// transitions instead of the typical blend.
        ///
        /// **Note:** If the pattern is not a gradient pattern, (eg. a linear
        /// or radial pattern), then the pattern will be put into an error
        /// status with a status of `cairo.Status.PatternTypeMismatch`, you
        /// don't have to worry about that unless you've casted a pointer from
        /// one pattern type into another, which you **SHOULDN'T**.
        ///
        /// **Parameters**
        /// - `offset`: an offset in the range [0.0 .. 1.0]
        /// - `red`: red component of color
        /// - `green`: green component of color
        /// - `blue`: blue component of color
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-add-color-stop-rgb)
        pub fn addColorStopRgb(self: *Self, offset: f64, red: f64, green: f64, blue: f64) void {
            c.cairo_pattern_add_color_stop_rgb(self, offset, red, green, blue);
        }

        /// Adds a translucent color stop to a gradient pattern. The offset
        /// specifies the location along the gradient's control vector. For
        /// example, a linear gradient's control vector is from (x0,y0) to
        /// (x1,y1) while a radial gradient's control vector is from any point
        /// on the start circle to the corresponding point on the end circle.
        ///
        /// The color is specified in the same way as in `cr.setSourceRgba()`.
        ///
        /// If two (or more) stops are specified with identical offset values,
        /// they will be sorted according to the order in which the stops are
        /// added, (stops added earlier will compare less than stops added
        /// later). This can be useful for reliably making sharp color
        /// transitions instead of the typical blend.
        ///
        /// **Note:** If the pattern is not a gradient pattern, (eg. a linear
        /// or radial pattern), then the pattern will be put into an error
        /// status with a status of `cairo.Status.PatternTypeMismatch`, you
        /// don't have to worry about that unless you've casted a pointer from
        /// one pattern type into another, which you **SHOULDN'T**.
        ///
        /// **Parameters**
        /// - `offset`: an offset in the range [0.0 .. 1.0]
        /// - `red`: red component of color
        /// - `green`: green component of color
        /// - `blue`: blue component of color
        /// - `alpha`: alpha component of color
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-add-color-stop-rgba)
        pub fn addColorStopRgba(self: *Self, offset: f64, red: f64, green: f64, blue: f64, alpha: f64) void {
            c.cairo_pattern_add_color_stop_rgba(self, offset, red, green, blue, alpha);
        }

        /// A convenience function that gets all color stops and offsets for
        /// this `color.Gradient`. Don't forget to `.deinit()`.
        pub fn getColorStops(self: *Self, allocator: Allocator) CairoError!ArrayList(ColorStop) {
            const num_stops = try self.getColorStopCount();
            var stops = try ArrayList(ColorStop).initCapacity(allocator, num_stops);
            for (0..num_stops) |n| {
                var stop: ColorStop = undefined;
                try self.getColorStopRgba(@intCast(n), &stop.offset, &stop.red, &stop.green, &stop.blue, &stop.alpha);
                try stops.append(stop);
            }
            return stops;
        }

        /// Gets the number of color stops specified in the given gradient
        /// pattern.
        ///
        /// **Returns**
        ///
        /// value for the number of color stops or `error.PatternTypeMismatch`
        /// if `self` is not a gradient pattern, you don't have to worry about
        /// that unless you've casted a pointer from one pattern type into
        /// another, which you **SHOULDN'T**.
        ///
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-count)
        pub fn getColorStopCount(self: *Self) CairoError!usize {
            var count: c_int = undefined;
            try c.cairo_pattern_get_color_stop_count(self, &count).toErr();
            return @intCast(count);
        }

        /// Gets the color and offset information at the given `index` for a
        /// gradient pattern. Values of `index` range from 0 to n-1 where n is the
        /// number returned by `pattern.getColorStopCount()`.
        ///
        /// **Parameters**
        /// - `index`: index of the stop to return data for
        /// - `offset`: return value for the offset of the stop, or `null`
        /// - `red`: return value for red component of color or `null`
        /// - `green`: return value for green component of color or `null`
        /// - `blue`: return value for blue component of color or `null`
        /// - `alpha`: return value for alpha component of color or `null`
        ///
        /// Possible errors are:
        /// - `InvalidIndex` if index is not valid for the given pattern.
        /// - `PatternTypeMismatch` (you don't have to worry about that unless
        /// you've casted a pointer from one pattern type into another, which
        /// you **SHOULDN'T**).
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-rgba)
        pub fn getColorStopRgba(self: *Self, index: c_int, offset: ?*f64, red: ?*f64, green: ?*f64, blue: ?*f64, alpha: ?*f64) CairoError!void {
            try c.cairo_pattern_get_color_stop_rgba(self, index, offset, red, green, blue, alpha).toErr();
        }
    };
}

pub const LinearGradientPattern = opaque {
    pub usingnamespace Gradient(@This());

    /// Create a new linear gradient `cairo.LinearGradientPattern` along the
    /// line defined by (x0, y0) and (x1, y1). Before using the gradient
    /// pattern, a number of color stops should be defined using
    /// `pattern.addColorStopRgb()` or `pattern.addColorStopRgba()`.
    ///
    /// Note: The coordinates here are in pattern space. For a new pattern,
    /// pattern space is identical to user space, but the relationship between
    /// the spaces can be changed with `pattern.setMatrix()`.
    ///
    /// **Parameters**
    /// - `x0`: x coordinate of the start point
    /// - `y0`: y coordinate of the start point
    /// - `x1`: x coordinate of the end point
    /// - `y1`: y coordinate of the end point
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.LinearGradientPattern` if successful, or an
    /// error in case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.LinearGradientPattern.create(0, 0, 100, 100);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-linear)
    pub fn create(x0: f64, y0: f64, x1: f64, y1: f64) CairoError!*LinearGradientPattern {
        var pattern = c.cairo_pattern_create_linear(x0, y0, x1, y1).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Gets the gradient endpoints for a linear gradient.
    ///
    /// **Parameters**
    /// - `x0`: return value for the x coordinate of the first point, or `null`
    /// - `y0`: return value for the y coordinate of the first point, or `null`
    /// - `x1`: return value for the x coordinate of the second point, or
    /// `null`
    /// - `y1`: return value for the y coordinate of the second point, or
    /// `null`
    ///
    /// The only possible error is `error.PatternTypeMismatch`, you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-linear-points)
    pub fn getLinearPoints(self: *LinearGradientPattern, x0: ?*f64, y0: ?*f64, x1: ?*f64, y1: ?*f64) CairoError!void {
        try c.cairo_pattern_get_linear_points(self, x0, y0, x1, y1).toErr();
    }
};

pub const RadialGradientPattern = opaque {
    pub usingnamespace Gradient(@This());

    /// Creates a new radial gradient `cairo.RadialGradientPattern` between the
    /// two circles defined by (cx0, cy0, radius0) and (cx1, cy1, radius1).
    /// Before using the gradient pattern, a number of color stops should be
    /// defined using `pattern.addColorStopRgb()` or
    /// `pattern.addColorStopRgba()`.
    ///
    /// Note: The coordinates here are in pattern space. For a new pattern,
    /// pattern space is identical to user space, but the relationship between
    /// the spaces can be changed with `pattern.setMatrix()`.
    ///
    /// **Parameters**
    /// - `cx0`: x coordinate for the center of the start circle
    /// - `cy0`: y coordinate for the center of the start circle
    /// - `radius0`: radius of the start circle
    /// - `cx1`: x coordinate for the center of the end circle
    /// - `cy1`: y coordinate for the center of the end circle
    /// - `radius1`: radius of the end circle
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.RadialGradientPattern` if successful, or an
    /// error in case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.RadialGradientPattern.create(0, 0, 10, 100, 100, 10);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-radial)
    pub fn create(cx0: f64, cy0: f64, radius0: f64, cx1: f64, cy1: f64, radius1: f64) CairoError!*RadialGradientPattern {
        var pattern = c.cairo_pattern_create_radial(cx0, cy0, radius0, cx1, cy1, radius1).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Gets the gradient endpoint circles for a radial gradient, each
    /// specified as a center coordinate and a radius.
    ///
    /// **Parameters**
    /// - `x0`: x coordinate for the center of the start circle
    /// - `y0`: y coordinate for the center of the start circle
    /// - `r0`: radius of the start circle
    /// - `x1`: x coordinate for the center of the end circle
    /// - `y1`: y coordinate for the center of the end circle
    /// - `r1`: radius of the end circle
    ///
    /// The only possible error is `error.PatternTypeMismatch`, you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-radial-circles)
    pub fn getRadialCircles(self: *RadialGradientPattern, x0: ?*f64, y0: ?*f64, r0: ?*f64, x1: ?*f64, y1: ?*f64, r1: ?*f64) CairoError!void {
        try c.cairo_pattern_get_radial_circles(self, x0, y0, r0, x1, y1, r1).toErr();
    }
};

/// Mesh patterns are tensor-product patch meshes (type 7 shadings in PDF).
/// Mesh patterns may also be used to create other types of shadings that
/// are special cases of tensor-product patch meshes such as Coons patch
/// meshes (type 6 shading in PDF) and Gouraud-shaded triangle meshes (type
/// 4 and 5 shadings in PDF).
///
/// Mesh patterns consist of one or more tensor-product patches, which
/// should be defined before using the mesh pattern. Using a mesh pattern
/// with a partially defined patch as source or mask will put the context
/// in an error status with a status of
/// `cairo.Status.InvalidMeshConstruction`.
///
/// A tensor-product patch is defined by 4 Bézier curves (side 0, 1, 2, 3)
/// and by 4 additional control points (P0, P1, P2, P3) that provide
/// further control over the patch and complete the definition of the
/// tensor-product patch. The corner C0 is the first point of the patch.
///
/// Degenerate sides are permitted so straight lines may be used. A zero
/// length line on one side may be used to create 3 sided patches.
/// ```code
///       C1     Side 1       C2
///        +---------------+
///        |               |
///        |  P1       P2  |
///        |               |
/// Side 0 |               | Side 2
///        |               |
///        |               |
///        |  P0       P3  |
///        |               |
///        +---------------+
///      C0     Side 3        C3
/// ```
/// Each patch is constructed by first calling `mesh_pattern.beginPatch()`,
/// then `mesh_pattern.moveTo()` to specify the first point in the patch (C0).
/// Then the sides are specified with calls to `mesh_pattern.curveTo()` and
/// `mesh_pattern.lineTo()`.
///
/// The four additional control points (P0, P1, P2, P3) in a patch can be
/// specified with `mesh_pattern.setControlPoint()`.
///
/// At each corner of the patch (C0, C1, C2, C3) a color may be specified with
/// `mesh_pattern.setCornerColorRgb()` or `mesh_pattern.setCornerColorRgba()`.
/// Any corner whose color is not explicitly specified defaults to transparent
/// black.
///
/// A Coons patch is a special case of the tensor-product patch where the
/// control points are implicitly defined by the sides of the patch. The
/// default value for any control point not specified is the implicit value for
/// a Coons patch, i.e. if no control points are specified the patch is a Coons
/// patch.
///
/// A triangle is a special case of the tensor-product patch where the control
/// points are implicitly defined by the sides of the patch, all the sides are
/// lines and one of them has length 0, i.e. if the patch is specified using
/// just 3 lines, it is a triangle. If the corners connected by the 0-length
/// side have the same color, the patch is a Gouraud-shaded triangle.
///
/// Patches may be oriented differently to the above diagram. For example the
/// first point could be at the top left. The diagram only shows the
/// relationship between the sides, corners and control points. Regardless of
/// where the first point is located, when specifying colors, corner 0 will
/// always be the first point, corner 1 the point between side 0 and side 1
/// etc.
///
/// Calling `mesh_pattern.endPatch()` completes the current patch. If less than
/// 4 sides have been defined, the first missing side is defined as a line from
/// the current point to the first point of the patch (C0) and the other sides
/// are degenerate lines from C0 to C0. The corners between the added sides
/// will all be coincident with C0 of the patch and their color will be set to
/// be the same as the color of C0.
///
/// Additional patches may be added with additional calls to
/// `mesh_pattern.beginPatch()`/`mesh_pattern.endPatch().
/// ```zig
/// const mesh_pattern = cairo.MeshPattern.create();
///
/// // Add a Coons patch
/// mesh_pattern.beginPatch();
/// mesh_pattern.moveTo(0, 0);
/// mesh_pattern.curveTo(30, -30,  60,  30, 100, 0);
/// mesh_pattern.curveTo(60,  30, 130,  60, 100, 100);
/// mesh_pattern.curveTo(60,  70,  30, 130,   0, 100);
/// mesh_pattern.curveTo(30,  70, -30,  30,   0, 0);
/// mesh_pattern.setCornerColorRgb(0, 1, 0, 0);
/// mesh_pattern.setCornerColorRgb(1, 0, 1, 0);
/// mesh_pattern.setCornerColorRgb(2, 0, 0, 1);
/// mesh_pattern.setCornerColorRgb(3, 1, 1, 0);
/// mesh_pattern.endPatch();
///
/// // Add a Gouraud-shaded triangle
/// mesh_pattern.beginPatch();
/// mesh_pattern.moveTo(100, 100);
/// mesh_pattern.lineTo(130, 130);
/// mesh_pattern.lineTo(130,  70);
/// mesh_pattern.setCornerColorRgb(0, 1, 0, 0);
/// mesh_pattern.setCornerColorRgb(1, 0, 1, 0);
/// mesh_pattern.setCornerColorRgb(2, 0, 0, 1);
/// mesh_pattern.endPatch();
/// ```
///
/// When two patches overlap, the last one that has been added is drawn over
/// the first one.
///
/// When a patch folds over itself, points are sorted depending on their
/// parameter coordinates inside the patch. The v coordinate ranges from 0 to 1
/// when moving from side 3 to side 1; the u coordinate ranges from 0 to 1 when
/// going from side 0 to side 1. Points with higher v coordinate hide points
/// with lower v coordinate. When two points have the same v coordinate, the
/// one with higher u coordinate is above. This means that points nearer to
/// side 1 are above points nearer to side 3; when this is not sufficient to
/// decide which point is above (for example when both points belong to side 1
/// or side 3) points nearer to side 2 are above points nearer to side 0.
///
/// For a complete definition of tensor-product patches, see the PDF
/// specification (ISO32000), which describes the parametrization in detail.
///
/// Note: The coordinates are always in pattern space. For a new pattern,
/// pattern space is identical to user space, but the relationship between the
/// spaces can be changed with `pattern.setMatrix()`.
pub const MeshPattern = opaque {
    pub usingnamespace Mixin(@This());

    /// Create a new mesh pattern.
    ///
    /// **Returns**
    ///
    /// the newly created `cairo.MeshPattern` if successful, or an error in
    /// case of no memory.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.MeshPattern.create();
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-mesh)
    pub fn create() CairoError!*MeshPattern {
        var pattern = c.cairo_pattern_create_mesh().?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Begin a patch in a mesh pattern.
    ///
    /// After calling this function, the patch shape should be defined with
    /// `mesh_pattern.moveTo()`, `mesh_pattern.lineTo()` and
    /// `mesh_pattern.curveTo()`.
    ///
    /// After defining the patch, `mesh_pattern.endPatch()` must be called
    /// before using `pattern` as a source or mask.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `pattern`
    /// already has a current patch, it will be put into an error status with a
    /// status of `cairo.Status.InvalidMeshConstruction`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-begin-patch)
    pub fn beginPatch(self: *MeshPattern) void {
        c.cairo_mesh_pattern_begin_patch(self);
    }

    // **Zig note**: you don't have to worry about that unless you cast pointers manually, which you **shouldn't**.

    /// Indicates the end of the current patch in a mesh pattern.
    ///
    /// If the current patch has less than 4 sides, it is closed with a
    /// straight line from the current point to the first point of the patch
    /// as if `mesh_pattern.lineTo()` was used.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`,
    /// you don't have to worry about that unless you've casted a pointer from
    /// one pattern type into another, which you **SHOULDN'T**. If `pattern`has
    /// no current patch or the current patch has no current point, `pattern`
    /// will be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-end-patch)
    pub fn endPatch(self: *MeshPattern) void {
        c.cairo_mesh_pattern_end_patch(self);
    }

    /// Define the first point of the current patch in a mesh pattern.
    ///
    /// After this call the current point will be `(x, y)`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `pattern` has no
    /// current patch or the current patch already has at least one side,
    /// `pattern` will be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `x`: the X coordinate of the new position
    /// - `y`: the Y coordinate of the new position
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-move-to)
    pub fn moveTo(self: *MeshPattern, x: f64, y: f64) void {
        c.cairo_mesh_pattern_move_to(self, x, y);
    }

    /// Adds a line to the current patch from the current point to position
    /// `(x, y)` in pattern-space coordinates.
    ///
    /// If there is no current point before the call to `mesh_pattern.lineTo()`
    /// this function will behave as `mesh_pattern.moveTo(x, y)`.
    ///
    /// After this call the current point will be `(x, y)`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `pattern` has no
    /// current patch or the current patch already has 4 sides, `pattern` will
    /// be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `x`: the X coordinate of the end of the new line
    /// - `y`: the Y coordinate of the end of the new line
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-line-to)
    pub fn lineTo(self: *MeshPattern, x: f64, y: f64) void {
        c.cairo_mesh_pattern_line_to(self, x, y);
    }

    /// Adds a cubic Bézier spline to the current patch from the current point
    /// to position `(x3, y3)` in pattern-space coordinates, using `(x1, y1)`
    /// and `(x2, y2)` as the control points.
    ///
    /// If the current patch has no current point before the call to
    /// `mesh_pattern.curveTo()`, this function will behave as if preceded by a
    /// call to `mesh_pattern.moveTo(x1, y1)`.
    ///
    /// After this call the current point will be `(x3, y3)`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `pattern` has no
    /// current patch or the current patch already has 4 sides, `pattern` will
    /// be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `x1`: the X coordinate of the first control point
    /// - `y1`: the Y coordinate of the first control point
    /// - `x2`: the X coordinate of the second control point
    /// - `y2`: the Y coordinate of the second control point
    /// - `x3`: the X coordinate of the end of the curve
    /// - `y3`: the Y coordinate of the end of the curve
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-curve-to)
    pub fn curveTo(self: *MeshPattern, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void {
        c.cairo_mesh_pattern_curve_to(self, x1, y1, x2, y2, x3, y3);
    }

    /// Set an internal control point of the current patch.
    ///
    /// Valid values for point_num are from 0 to 3 and identify the control
    /// points as explained in documentation to `cairo.MeshPattern`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `pattern` has no
    /// current patch, `pattern` will be put into an error status with a status
    /// of `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `point_num`: the control point to set the position for
    /// - `point`: the control point
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-set-control-point)
    pub fn setControlPoint(self: *MeshPattern, point_num: c_uint, point: Point) void {
        c.cairo_mesh_pattern_set_control_point(self, point_num, point.x, point.y);
    }

    /// Sets the color of a corner of the current patch in a mesh pattern.
    ///
    /// The color is specified in the same way as in
    /// `cairo.Context.setSourceRgb()`.
    ///
    /// Valid values for corner_num are from 0 to 3 and identify the corners as
    /// explained in documentation to `cairo.MeshPattern`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `corner_num` is
    /// not valid, pattern will be put into an error status with a status of
    /// `cairo.Status.InvalidIndex`. If pattern has no current patch, pattern
    /// will be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `corner_num`: the corner to set the color for
    /// - `red`: red component of color
    /// - `green`: green component of color
    /// - `blue`: blue component of color
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-set-corner-color-rgb)
    pub fn setCornerColorRgb(self: *MeshPattern, corner_num: c_uint, red: f64, green: f64, blue: f64) void {
        c.cairo_mesh_pattern_set_corner_color_rgb(self, corner_num, red, green, blue);
    }

    /// Sets the color of a corner of the current patch in a mesh pattern.
    ///
    /// The color is specified in the same way as in
    /// `cairo.Context.setSourceRgba()`.
    ///
    /// Valid values for corner_num are from 0 to 3 and identify the corners as
    /// explained in documentation to `cairo.MeshPattern`.
    ///
    /// Note: If `self` is not a mesh pattern then `self` will be put into an
    /// error status with a status of `cairo.Status.PatternTypeMismatch`, you
    /// don't have to worry about that unless you've casted a pointer from one
    /// pattern type into another, which you **SHOULDN'T**. If `corner_num` is
    /// not valid, pattern will be put into an error status with a status of
    /// `cairo.Status.InvalidIndex`. If pattern has no current patch, pattern
    /// will be put into an error status with a status of
    /// `cairo.Status.InvalidMeshConstruction`.
    ///
    /// **Parameters**
    /// - `corner_num`: the corner to set the color for
    /// - `red`: red component of color
    /// - `green`: green component of color
    /// - `blue`: blue component of color
    /// - `alpha`: alpha component of color
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-set-corner-color-rgba)
    pub fn setCornerColorRgba(self: *MeshPattern, corner_num: c_uint, red: f64, green: f64, blue: f64, alpha: f64) void {
        c.cairo_mesh_pattern_set_corner_color_rgba(self, corner_num, red, green, blue, alpha);
    }

    /// Gets the number of patches specified in the given mesh pattern.
    ///
    /// The number only includes patches which have been finished by calling
    /// `mesh_pattern.endPatch()`. For example it will be 0 during the
    /// definition of the first patch.
    ///
    /// **Returns**
    ///
    /// the number of patches.
    ///
    /// The only possible error is `error.PatternTypeMismatch`, you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-patch-count)
    pub fn getPatchCount(self: *MeshPattern) CairoError!usize {
        var count: c_uint = undefined;
        try c.cairo_mesh_pattern_get_patch_count(self, &count).toErr();
        return @intCast(count);
    }

    /// Gets path defining the patch `patch_num` for a mesh pattern.
    ///
    /// `patch_num` can range from 0 to n-1 where n is the number returned by
    /// `mesh_pattern.getPatchCount()`.
    ///
    /// **Parameters**
    /// - `patch_num`: the patch number to return data for
    ///
    /// **Returns**
    ///
    /// the path defining the patch, or a path with status
    /// `cairo.Status.InvalidIndex` if `patch_num` is not valid for `pattern`.
    /// If `pattern` is not a mesh pattern, a path with status
    /// `cairo.Status.PatternTypeMismatch` is returned, you don't have to worry
    /// about that unless you've casted a pointer from one pattern type into
    /// another, which you **SHOULDN'T**.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-path)
    pub fn getPath(self: *MeshPattern, patch_num: u32) *Path {
        // TODO: who ownes this? check with valgrind or smth, ChatGPT says:
        // Based on the available information, the ownership of the struct
        // returned by the c.cairo_mesh_pattern_get_path function depends on
        // whether the user has finished defining the patch or not:
        // 1. If the user has not finished defining the patch, the returned
        // struct is still owned by the library. The user should not destroy
        // it explicitly.
        // 2. If the user has finished defining the patch using
        // c.cairo_mesh_pattern_end_patch, then the user becomes the owner of the
        // returned struct and is responsible for destroying it when it is no
        // longer needed.
        return c.cairo_mesh_pattern_get_path(self, @intCast(patch_num)).?;
    }

    /// Gets the control point `point_num` of patch `patch_num` for a mesh
    /// pattern.
    ///
    /// `patch_num` can range from 0 to n-1 where n is the number returned by
    /// `mesh_pattern.getPatchCount()`.
    ///
    /// Valid values for point_num are from 0 to 3 and identify the control
    /// points as explained in documentation to `cairo.MeshPattern`.
    ///
    /// **Parameters**
    /// - `patch_num`: the patch number to return data for
    /// - `point_num`: the control point number to return data for
    ///
    /// **Returns**
    ///
    /// coordinates of the control point.
    ///
    /// Possible errors are: `error.InvalidIndex` if `patch_num` or `point_num`
    /// is not valid for `self` and `error.PatternTypeMismatch` (you don't have
    /// to worry about that unless you've casted a pointer from one pattern
    /// type into another, which you **SHOULDN'T**).
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-control-point)
    pub fn getControlPoint(self: *MeshPattern, patch_num: u32, point_num: u32) CairoError!Point {
        // TODO: check if undefined is problematic here
        var point: Point = undefined;
        try c.cairo_mesh_pattern_get_control_point(self, @intCast(patch_num), @intCast(point_num), &point.x, &point.y).toErr();
        return point;
    }

    /// Gets the color information in corner `corner_num` of patch `patch_num`
    /// for a mesh pattern.
    ///
    /// `patch_num` can range from 0 to n-1 where n is the number returned by
    /// `mesh_pattern.getPatchCount()`.
    ///
    /// Valid values for point_num are from 0 to 3 and identify the control
    /// points as explained in documentation to `cairo.MeshPattern`.
    ///
    /// **Parameters**
    /// - `patch_num`: the patch number to return data for
    /// - `corner_num`: the corner number to return data for
    /// - `red`: return value for red component of color, or `null`
    /// - `green`: return value for green component of color, or `null`
    /// - `blue`: return value for blue component of color, or `null`
    /// - `alpha`: return value for alpha component of color, or `null`
    ///
    /// Possible errors are: `error.InvalidIndex` if `patch_num` or
    /// `corner_num` is not valid for `self` and `error.PatternTypeMismatch`
    /// (you don't have to worry about that unless you've casted a pointer from
    /// one pattern type into another, which you **SHOULDN'T**).
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-mesh-pattern-get-corner-color-rgba)
    pub fn getCornerColorRgba(self: *MeshPattern, patch_num: u32, corner_num: u32, red: ?*f64, green: ?*f64, blue: ?*f64, alpha: ?*f64) CairoError!void {
        try c.cairo_mesh_pattern_get_corner_color_rgba(self, @intCast(patch_num), @intCast(corner_num), red, green, blue, alpha).toErr();
    }
};

/// Raster Sources — Supplying arbitrary image data
///
/// The raster source provides the ability to supply arbitrary pixel data
/// whilst rendering. The pixels are queried at the time of rasterisation by
/// means of user callback functions, allowing for the ultimate flexibility.
/// For example, in handling compressed image sources, you may keep a MRU cache
/// of decompressed images and decompress sources on the fly and discard old
/// ones to conserve memory.
///
/// For the raster source to be effective, you must at least specify the
/// acquire and release callbacks which are used to retrieve the pixel data for
/// the region of interest and demark when it can be freed afterwards. Other
/// callbacks are provided for when the pattern is copied temporarily during
/// rasterisation, or more permanently as a snapshot in order to keep the pixel
/// data available for printing.
pub const RasterSourcePattern = opaque {
    pub usingnamespace Mixin(@This());

    /// Creates a new user pattern for providing pixel data.
    ///
    /// Use the setter functions to associate callbacks with the returned pattern.
    /// The only mandatory callback is acquire.
    ///
    /// **Parameters**
    /// - `user_data`: the user data to be passed to all callbacks
    /// - `content`: content type for the pixel data that will be returned. Knowing
    /// the content type ahead of time is used for analysing the operation and
    /// picking the appropriate rendering path.
    /// - `width`: maximum size of the sample area
    /// - `height`: maximum size of the sample area
    ///
    /// **Returns**
    ///
    /// a newly created `cairo.RasterSourcePattern`.
    ///
    /// **NOTE**: The caller owns the returned object and should call
    /// `pattern.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const pattern = cairo.RasterSourcePattern.create(...);
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-pattern-create-raster-source)
    pub fn create(user_data: ?*anyopaque, content: Content, width: c_int, height: c_int) CairoError!*Pattern {
        // TODO: fix doc example
        const pattern = c.cairo_pattern_create_raster_source(user_data, content, width, height).?;
        try pattern.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), pattern);
        return pattern;
    }

    /// Updates the user data that is provided to all callbacks.
    ///
    /// **Parameters**
    /// - `data`: the user data to be passed to all callbacks
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-callback-data)
    pub fn setCallbackData(self: *RasterSourcePattern, data: ?*anyopaque) void {
        c.cairo_raster_source_pattern_set_callback_data(self, data);
    }

    /// Queries the current user data.
    ///
    /// **Returns**
    ///
    /// the current user-data passed to each callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-get-callback-data)
    pub fn getCallbackData(self: *RasterSourcePattern) ?*anyopaque {
        return c.cairo_raster_source_pattern_get_callback_data(self);
    }

    /// Specifies the callbacks used to generate the image surface for a
    /// rendering operation (acquire) and the function used to cleanup that
    /// surface afterwards.
    ///
    /// The `acquire` callback should create a surface (preferably an image
    /// surface created to match the target using
    /// `cairo.Surface.createSimilarImage()`) that defines at least the region
    /// of interest specified by extents. The surface is allowed to be the
    /// entire sample area, but if it does contain a subsection of the sample
    /// area, the surface extents should be provided by setting the device
    /// offset (along with its width and height) using
    /// `cairo.Surface.setDeviceOffset()`.
    ///
    /// **Parameters**
    /// - `acquire`: the acquire callback
    /// - `release`: the release callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-acquire)
    pub fn setAcquire(self: *RasterSourcePattern, acquire: RasterSourcePattern.AcquireFn, release: RasterSourcePattern.ReleaseFn) void {
        c.cairo_raster_source_pattern_set_acquire(self, acquire, release);
    }

    /// Queries the current acquire and release callbacks.
    ///
    /// **Parameters**
    /// - `acquire`: return value for the current acquire callback
    /// - `release`: return value for the current release callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-get-acquire)
    pub fn getAcquire(self: *RasterSourcePattern, acquire: *RasterSourcePattern.AcquireFn, release: *RasterSourcePattern.ReleaseFn) void {
        c.cairo_raster_source_pattern_get_acquire(self, acquire, release);
    }

    /// Sets the callback that will be used whenever a snapshot is taken of the
    /// pattern, that is whenever the current contents of the pattern should be
    /// preserved for later use. This is typically invoked whilst printing.
    ///
    /// **Parameters**
    /// - `snapshot`: the snapshot callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-snapshot)
    pub fn setSnapshot(self: *RasterSourcePattern, snapshot: RasterSourcePattern.SnapshotFn) void {
        c.cairo_raster_source_pattern_set_snapshot(self, snapshot);
    }

    /// Queries the current snapshot callback.
    ///
    /// **Returns**
    ///
    /// the current snapshot callback.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-get-snapshot)
    pub fn getSnapshot(self: *RasterSourcePattern) RasterSourcePattern.SnapshotFn {
        return c.cairo_raster_source_pattern_get_snapshot(self);
    }

    /// Updates the copy callback which is used whenever a temporary copy of
    /// the pattern is taken.
    ///
    /// **Parameters**
    /// - `copy`: the copy callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-copy)
    pub fn setCopy(self: *RasterSourcePattern, copy: RasterSourcePattern.CopyFn) void {
        c.cairo_raster_source_pattern_set_copy(self, copy);
    }

    /// Queries the current copy callback.
    ///
    /// **Returns**
    ///
    /// the current copy callback.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-get-copy)
    pub fn getCopy(self: *RasterSourcePattern) RasterSourcePattern.CopyFn {
        return c.cairo_raster_source_pattern_get_copy(self);
    }

    /// Updates the finish callback which is used whenever a pattern (or a copy
    /// thereof) will no longer be used.
    ///
    /// **Parameters**
    /// - `copy`: the finish callback
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-finish)
    pub fn setFinish(self: *RasterSourcePattern, finish: RasterSourcePattern.FinishFn) void {
        c.cairo_raster_source_pattern_set_finish(self, finish);
    }

    /// Queries the current finish callback.
    ///
    /// **Returns**
    ///
    /// the current finish callback.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-get-finish)
    pub fn getFinish(self: *RasterSourcePattern) RasterSourcePattern.FinishFn {
        return c.cairo_raster_source_pattern_get_finish(self);
    }

    /// `cairo.RasterSourcePattern.AcquireFn` is the type of function which is
    /// called when a pattern is being rendered from. It should create a
    /// surface that provides the pixel data for the region of interest as
    /// defined by extents, though the surface itself does not have to be
    /// limited to that area. For convenience the surface should probably be of
    /// image type, created with `cairo.Surface.createSimilarImage()` for the
    /// target (which enables the number of copies to be reduced during
    /// transfer to the device). Another option, might be to return a similar
    /// surface to the target for explicit handling by the application of a set
    /// of cached sources on the device. The region of sample data provided
    /// should be defined using `cairo.Surface.setDeviceOffset()` to specify
    /// the top-left corner of the sample data (along with width and height of
    /// the surface).
    ///
    /// **Parameters**
    /// - `pattern`: the pattern being rendered from
    /// - `callback_data`: the user data supplied during creation
    /// - `target`: the rendering target surface
    /// - `extents`: rectangular region of interest in pixels in sample space
    ///
    /// **Returns**
    ///
    /// a `cairo.Surface`
    ///
    /// [Lnk to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-acquire-func-t)
    pub const AcquireFn = *const fn (pattern: ?*Pattern, callback_data: ?*anyopaque, target: ?*Surface, extents: ?*const RectangleInt) callconv(.C) ?*Surface;

    /// `cairo.RasterSourcePattern.ReleaseFn` is the type of function which is
    /// called when the pixel data is no longer being access by the pattern for
    /// the rendering operation. Typically this function will simply destroy
    /// the surface created during acquire.
    ///
    /// **Parameters**
    /// - `pattern`: the pattern being rendered from
    /// - `callback_data`: the user data supplied during creation
    /// - `surface`: the surface created during acquire
    ///
    /// [Lnk to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-release-func-t)
    pub const ReleaseFn = ?*const fn (pattern: ?*Pattern, callback_data: ?*anyopaque, surface: ?*Surface) callconv(.C) void;

    /// `cairo.RasterSourcePattern.SnapshotFn` is the type of function which is
    /// called when the pixel data needs to be preserved for later use during
    /// printing. This pattern will be accessed again later, and it is expected
    /// to provide the pixel data that was current at the time of snapshotting.
    ///
    /// **Parameters**
    /// - `pattern`: the pattern being rendered from
    /// - `callback_data`: the user data supplied during creation
    ///
    /// **Returns**
    ///
    /// `cairo.Status.Success` on success, or one of the `cairo.Status` error
    /// codes for failure.
    ///
    /// [Lnk to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-snapshot-func-t)
    pub const SnapshotFn = ?*const fn (pattern: ?*Pattern, callback_data: ?*anyopaque) callconv(.C) Status;

    /// `cairo.RasterSourcePattern.CopyFn` is the type of function which is
    /// called when the pattern gets copied as a normal part of rendering.
    ///
    /// **Parameters**
    /// - `pattern`: the `cairo.Pattern` that was copied to
    /// - `callback_data`: the user data supplied during creation
    /// - `other`: the `cairo.Pattern` being used as the source for the copy
    ///
    /// **Returns**
    ///
    /// `cairo.Status.Success` on success, or one of the `cairo.Status` error
    /// codes for failure.
    ///
    /// [Lnk to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-copy-func-t)
    pub const CopyFn = ?*const fn (pattern: ?*Pattern, callback_data: ?*anyopaque, other: ?*const Pattern) callconv(.C) Status;

    /// `cairo.RasterSourcePattern.SnapshotFn` is the type of function which is
    /// called when the pattern (or a copy thereof) is no longer required.
    ///
    /// **Parameters**
    /// - `pattern`: the pattern being rendered from
    /// - `callback_data`: the user data supplied during creation
    ///
    /// [Lnk to Cairo manual](https://www.cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-finish-func-t)
    pub const FinishFn = ?*const fn (pattern: ?*Pattern, callback_data: ?*anyopaque) callconv(.C) void;
};

/// Holds info about color stop for gradient patterns
pub const ColorStop = struct {
    offset: f64,
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};
