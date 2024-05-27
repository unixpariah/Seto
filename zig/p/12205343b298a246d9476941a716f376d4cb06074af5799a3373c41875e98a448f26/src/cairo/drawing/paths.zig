//! Paths — Creating paths and manipulating path data
//!
//! Paths are the most basic drawing tools and are primarily used to implicitly
//! generate simple masks.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html)

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Context = cairo.Context;
const Rectangle = cairo.Rectangle;
const ExtentsRectangle = cairo.ExtentsRectangle;
const Glyph = cairo.Glyph;
const Point = cairo.Point;

const CairoError = cairo.CairoError;
const Status = cairo.Status;

pub const Mixin = struct {
    /// Creates a copy of the current path and returns it to the user as a
    /// `cairo.Path`. See `cairo.PathData` for hints on how to iterate over the
    /// returned data structure.
    ///
    /// Possible errors are:
    /// - `error.OutOfMemory` if there is insufficient memory to copy the path.
    /// -  If 'self' is already in an error state, respective error will be
    /// raised.
    ///
    /// **Returns**
    ///
    /// the copy of the current path. The caller owns the returned object and
    /// should call `path.destroy()` when finished with it.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-copy-path)
    pub fn copyPath(self: *Context) CairoError!*Path {
        var path: *Path = c.cairo_copy_path(self).?;
        try path.status.toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), path);
        return path;
    }

    /// Gets a flattened copy of the current path and returns it to the user as
    /// a `cairo.Path`. See `cairo.PathData` for hints on how to iterate over
    /// the returned data structure.
    ///
    /// This function is like `cr.copyPath()` except that any curves in the
    /// path will be approximated with piecewise-linear approximations,
    /// (accurate to within the current tolerance value). That is, the result
    /// is guaranteed to not have any elements of type `.CurveTo` which will
    /// instead be replaced by a series of `.LineTo` elements.
    ///
    /// Possible errors are:
    /// - `error.OutOfMemory` if there is insufficient memory to copy the path.
    /// -  If 'self' is already in an error state, respective error will be
    /// raised.
    ///
    /// **Returns**
    ///
    /// the copy of the current path. The caller owns the returned object and
    /// should call `path.destroy()` when finished with it.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-copy-path-flat)
    pub fn copyPathFlat(self: *Context) CairoError!*Path {
        var path: *Path = c.cairo_copy_path_flat(self).?;
        try path.status.toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), path);
        return path;
    }

    /// Append the `path` onto the current path. The path may be either the
    /// return value from one of `cr.copyPath()` or `cr.copyFlatPath()` or it
    /// may be constructed manually. See `cairo.Path` for details on how the
    /// path data structure should be initialized, and note that `path.status`
    /// must be initialized to `.Success`.
    ///
    /// **Parameters**
    /// - `path`: path to be appended
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-append-path)
    pub fn appendPath(self: *Context, path: *const Path) void {
        c.cairo_append_path(self, path);
    }

    /// Returns whether a current point is defined on the current path.
    /// See `cairo.Context.getCurrentPoint()` for details on the current point.
    ///
    /// **Returns**
    ///
    /// whether a current point is defined.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-has-current-point)
    pub fn hasCurrentPoint(self: *Context) bool {
        return c.cairo_has_current_point(self) > 0;
    }

    /// Gets the current point of the current path, which is conceptually the
    /// final point reached by the path so far.
    ///
    /// The current point is returned in the user-space coordinate system. If
    /// there is no defined current point or if `self` is in an error status,
    /// `x` and `y` will both be set to `0.0`. It is possible to check this in
    /// advance with `cr.hasCurrentPoint()`.
    ///
    /// Most path construction functions alter the current point. See the
    /// following for details on how they affect the current point:
    /// `cr.newPath()`, `cr.newSubPath()`, `cr.appendPath()`, `cr.closePath()`,
    /// `cr.moveTo()`, `cr.lineTo()`, `cr.curveTo()`, `cr.relMoveTo()`,
    /// `cr.relLineTo()`, `cr.relCurveTo()`, `cr.arc()`, `cr.arcNegative()`,
    /// `cr.rectangle()`, `cr.textPath()`, `cr.glyphPath()`,
    /// `cr.strokeToPath(`).
    ///
    /// Some functions use and alter the current point but do not otherwise
    /// change current path: `cr.showText()`.
    ///
    /// Some functions unset the current path and as a result, current point:
    /// `cr.fill()`, `cr.stroke()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-get-current-point)
    pub fn getCurrentPoint(self: *Context) Point {
        // TODO: check if undefined behaves well with C
        var point: Point = undefined;
        c.cairo_get_current_point(self, &point.x, &point.y);
        return point;
    }

    /// Clears the current path. After this call there will be no path and no
    /// current point.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-new-path)
    pub fn newPath(self: *Context) void {
        c.cairo_new_path(self);
    }

    /// Begin a new sub-path. Note that the existing path is not affected.
    /// After this call there will be no current point.
    ///
    /// In many cases, this call is not needed since new sub-paths are
    /// frequently started with `cr.moveTo()`.
    ///
    /// A call to `cr.newSubPath()` is particularly useful when beginning a new
    /// sub-path with one of the `cr.arc()` calls. This makes things easier as
    /// it is no longer necessary to manually compute the arc's initial
    /// coordinates for a call to `cr.moveTo()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-new-sub-path)
    pub fn newSubPath(self: *Context) void {
        c.cairo_new_sub_path(self);
    }

    /// Adds a line segment to the path from the current point to the beginning
    /// of the current sub-path, (the most recent point passed to
    /// `cr.moveTo()`), and closes this sub-path. After this call the current
    /// point will be at the joined endpoint of the sub-path.
    ///
    /// The behavior of `cr.closePath()` is distinct from simply calling
    /// `cr.lineTo()` with the equivalent coordinate in the case of stroking.
    /// When a closed sub-path is stroked, there are no caps on the ends of the
    /// sub-path. Instead, there is a line join connecting the final and
    /// initial segments of the sub-path.
    ///
    /// If there is no current point before the call to `cr.closePath()`, this
    /// function will have no effect.
    ///
    /// **Note:** As of cairo version 1.2.4 any call to `cr.closePath()` will
    /// place an explicit `.MoveTo` element into the path immediately after the
    /// `.ClosePath` element, (which can be seen in `cr.copyPath()` for
    /// example). This can simplify path processing in some cases as it may not
    /// be necessary to save the "last move_to point" during processing as the
    /// `.MoveTo` immediately after the `.ClosePath` will provide that point.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-close-path)
    pub fn closePath(self: *Context) void {
        c.cairo_close_path(self);
    }

    /// Adds a circular arc of the given `radius` to the current path. The arc
    /// is centered at (`xc`, `yc`), begins at `angle1` and proceeds in the
    /// direction of increasing angles to end at `angle2`. If `angle2` is less
    /// than `angle1` it will be progressively increased by `2*std.math.pi`
    /// until it is greater than `angle1`.
    ///
    /// If there is a current point, an initial line segment will be added to
    /// the path to connect the current point to the beginning of the arc. If
    /// this initial line is undesired, it can be avoided by calling
    /// `cr.newSubPath()` before calling `cr.arc()`.
    ///
    /// Angles are measured in radians. An angle of 0.0 is in the direction of
    /// the positive X axis (in user space). An angle of `std.math.pi/2.0`
    /// radians (90 degrees) is in the direction of the positive Y axis (in
    /// user space). Angles increase in the direction from the positive X axis
    /// toward the positive Y axis. So with the default transformation matrix,
    /// angles increase in a clockwise direction.
    ///
    /// To convert from degrees to radians, use `degrees * (std.math.pi /
    /// 180.0)`.
    ///
    /// This function gives the arc in the direction of increasing angles; see
    /// `cairo.Context.arcNegative()` to get the arc in the direction of
    /// decreasing angles.
    ///
    /// The arc is circular in user space. To achieve an elliptical arc, you
    /// can scale the current transformation matrix by different amounts in the
    /// X and Y directions. For example, to draw an ellipse in the box given by
    /// `x`, `y`, `width`, `height`:
    /// ```zig
    /// cr.save();
    /// cr.translate(x + width / 2.0, y + height / 2.0);
    /// cr.scale(width / 2.0, height / 2.0);
    /// cr.arc(0.0, 0.0, 1.0, 0.0, 2.0 * std.math.pi);
    /// cr.restore();
    /// ```
    /// **Parameters**
    /// - `xc`: X position of the center of the arc
    /// - `yc`: Y position of the center of the arc
    /// - `raduis`: the radius of the arc
    /// - `angle1`: the start angle, in radians
    /// - `angle2`: the end angle, in radians
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-arc)
    pub fn arc(self: *Context, xc: f64, yc: f64, radius: f64, angle1: f64, angle2: f64) void {
        c.cairo_arc(self, xc, yc, radius, angle1, angle2);
    }

    /// Adds a circular arc of the given `radius` to the current path. The arc
    /// is centered at (`xc`, `yc`), begins at `angle1` and proceeds in the
    /// direction of decreasing angles to end at `angle2`. If `angle2` is
    /// greater than `angle1` it will be progressively decreased by
    /// `2*std.math.pi` until it is less than `angle1`.
    ///
    /// See `cairo.Context.arc()` for more details. This function differs only
    /// in the direction of the arc between the two angles.
    ///
    /// **Parameters**
    /// - `xc`: X position of the center of the arc
    /// - `yc`: Y position of the center of the arc
    /// - `raduis`: the radius of the arc
    /// - `angle1`: the start angle, in radians
    /// - `angle2`: the end angle, in radians
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-arc-negative)
    pub fn arcNegative(self: *Context, xc: f64, yc: f64, radius: f64, angle1: f64, angle2: f64) void {
        c.cairo_arc_negative(self, xc, yc, radius, angle1, angle2);
    }

    /// Adds a cubic Bézier spline to the path from the current point to
    /// position `(x3, y3)` in user-space coordinates, using `(x1, y1)` and
    /// `(x2, y2)` as the control points. After this call the current point
    /// will be `(x3, y3)`.
    ///
    /// If there is no current point before the call to `cr.curveTo()` this
    /// function will behave as if preceded by a call to `cr.moveTo(x1, y1)`.
    ///
    /// **Parameters**
    /// - `x1`: the X coordinate of the first control point
    /// - `y1`: the Y coordinate of the first control point
    /// - `x2`: the X coordinate of the second control point
    /// - `y2`: the Y coordinate of the second control point
    /// - `x3`: the X coordinate of the end of the curve
    /// - `y3`: the Y coordinate of the end of the curve
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-curve-to)
    pub fn curveTo(self: *Context, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void {
        c.cairo_curve_to(self, x1, y1, x2, y2, x3, y3);
    }

    /// Adds a line to the path from the current point to position `(x, y)` in
    /// user-space coordinates. After this call the current point will be
    /// `(x, y)`.
    ///
    /// If there is no current point before the call to `cr.lineTo()` this
    /// function will behave as `cr.moveTo(x, y)`.
    ///
    /// **Parameters**
    /// - `x`: the X coordinate of the end of the new line
    /// - `y`: the Y coordinate of the end of the new line
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-line-to)
    pub fn lineTo(self: *Context, x: f64, y: f64) void {
        c.cairo_line_to(self, x, y);
    }

    /// Begin a new sub-path. After this call the current point will be
    /// `(x, y)`.
    ///
    /// **Parameters**
    /// - `x`: the X coordinate of the new position
    /// - `y`: the Y coordinate of the new position
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-move-to)
    pub fn moveTo(self: *Context, x: f64, y: f64) void {
        c.cairo_move_to(self, x, y);
    }

    /// Adds a closed sub-path rectangle of the given size to the current path
    /// at position `(rect.x, rect.y)` in user-space coordinates.
    ///
    /// This function is logically equivalent to:
    /// ```zig
    /// cr.moveTo(x, y);
    /// cr.relLineTo(width, 0);
    /// cr.relLineTo(0, height);
    /// cr.relLineTo(-width, 0);
    /// cr.closePath();
    /// ```
    /// **Parameters**
    /// - `rect`: `cairo.Rectangle` with coordinates of the rectangle
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-rectangle)
    pub fn rectangle(self: *Context, rect: Rectangle) void {
        c.cairo_rectangle(self, rect.x, rect.y, rect.width, rect.height);
    }

    /// Adds closed paths for the glyphs to the current path. The generated
    /// path if filled, achieves an effect similar to that of
    /// `cairo.Context.showGlyphs()`.
    ///
    /// **Parameters**
    /// - `glyphs`: slice of glyphs to show
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-glyph-path)
    pub fn glyphPath(self: *Context, glyphs: []const Glyph) void {
        c.cairo_glyph_path(self, glyphs.ptr, @intCast(glyphs.len));
    }

    /// Adds closed paths for text to the current path. The generated path if
    /// filled, achieves an effect similar to that of `cr.showText()`.
    ///
    /// Text conversion and positioning is done similar to `cr.showText()`.
    ///
    /// Like `cr.showText()`, After this call the current point is moved to
    /// the origin of where the next glyph would be placed in this same
    /// progression. That is, the current point will be at the origin of the
    /// final glyph offset by its advance values. This allows for chaining
    /// multiple calls to to `cr.textPath()` without having to set current
    /// point in between.
    ///
    /// **Note:** The `cr.textPath()` function call is part of what the cairo
    /// designers call the "toy" text API. It is convenient for short demos and
    /// simple programs, but it is not expected to be adequate for serious
    /// text-using applications. See `cr.glyphPath()` for the "real" text path
    /// API in cairo.
    ///
    /// **Parameters**
    /// - `utf8`: a 0-sentinel string of text encoded in UTF-8, or `null`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-text-path)
    pub fn textPath(self: *Context, utf8: ?[:0]const u8) void {
        c.cairo_text_path(self, utf8 orelse null);
    }

    /// Relative-coordinate version of `cr.curveTo()`. All offsets are
    /// relative to the current point. Adds a cubic Bézier spline to the path
    /// from the current point to a point offset from the current point by
    /// `(dx3, dy3)`, using points offset by `(dx1, dy1)` and `(dx2, dy2)` as
    /// the control points. After this call the current point will be offset by
    /// `(dx3, dy3)`.
    ///
    /// Given a current point of `(x, y)`,
    /// ```
    /// cr.relCurveTo(dx1, dy1, dx2, dy2, dx3, dy3);
    /// ```
    /// is logically equivalent to
    /// ```
    /// cr.curveTo(x+dx1, y+dy1, x+dx2, y+dy2, x+dx3, y+dy3);
    /// ```
    /// It is an error to call this function with no current point. Doing so
    /// will cause `self` to shutdown with a status of
    /// `cairo.Status.NoCurrentPoint`.
    ///
    /// **Parameters**
    /// - `dx1`: the X offset to the first control point
    /// - `dy1`: the Y offset to the first control point
    /// - `dx2`: the X offset to the second control point
    /// - `dy2`: the Y offset to the second control point
    /// - `dx3`: the X offset to the end of the curve
    /// - `dy3`: the Y offset to the end of the curve
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-rel-curve-to)
    pub fn relCurveTo(self: *Context, dx1: f64, dy1: f64, dx2: f64, dy2: f64, dx3: f64, dy3: f64) void {
        c.cairo_rel_curve_to(self, dx1, dy1, dx2, dy2, dx3, dy3);
    }

    /// Relative-coordinate version of `cr.lineTo()`. Adds a line to the path
    /// from the current point to a point that is offset from the current point
    /// by `(dx, dy)` in user space. After this call the current point will be
    /// offset by `(dx, dy)`.
    ///
    /// Given a current point of `(x, y)`, `cr.relLineTo(dx, dy)` is logically
    /// equivalent to `cr.lineTo(x + dx, y + dy)`.
    ///
    /// It is an error to call this function with no current point. Doing so
    /// will cause `self` to shutdown with a status of
    /// `cairo.Status.NoCurrentPoint`.
    ///
    /// **Parameters**
    /// - `dx`: the X offset to the end of the new line
    /// - `dy`: the Y offset to the end of the new line
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-rel-line-to)
    pub fn relLineTo(self: *Context, dx: f64, dy: f64) void {
        c.cairo_rel_line_to(self, dx, dy);
    }

    /// Begin a new sub-path. After this call the current point will offset by
    /// `(dx, dy)`.
    ///
    /// Given a current point of `(x, y)`, `cr.relMoveTo(dx, dy)` is logically
    /// equivalent to `cr.moveTo(x + dx, y + dy)`.
    ///
    /// It is an error to call this function with no current point. Doing so
    /// will cause `self` to shutdown with a status of
    /// `cairo.Status.NoCurrentPoint`.
    ///
    /// **Parameters**
    /// - `dx`: the X offset
    /// - `dy`: the Y offset
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-rel-move-to)
    pub fn relMoveTo(self: *Context, dx: f64, dy: f64) void {
        c.cairo_rel_move_to(self, dx, dy);
    }

    /// Computes a bounding box in user-space coordinates covering the points
    /// on the current path. If the current path is empty, returns an empty
    /// rectangle `((0,0), (0,0))`. Stroke parameters, fill rule, surface
    /// dimensions and clipping are not taken into account.
    ///
    /// Contrast with `cr.fillExtents()` and `cr.strokeExtents()` which
    /// return the extents of only the area that would be "inked" by the
    /// corresponding drawing operations.
    ///
    /// The result of `cr.pathExtents()` is defined as equivalent to the
    /// limit of `cr.strokeExtents()` with `cairo.Context.LineCap.Round` as
    /// the line width approaches 0.0, (but never reaching the empty-rectangle
    /// returned by `cr.strokeExtents()` for a line width of 0.0).
    ///
    /// Specifically, this means that zero-area sub-paths such as
    /// `cr.moveTo()`; `cr.lineTo()` segments, (even degenerate cases where
    /// the coordinates to both calls are identical), will be considered as
    /// contributing to the extents. However, a lone `cr.moveTo()` will not
    /// contribute to the results of `cr.pathExtents()`.
    ///
    /// **Parameters**
    /// - `extents`: resulting extents
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-path-extents)
    pub fn pathExtents(self: *Context, extents: *ExtentsRectangle) void {
        c.cairo_path_extents(self, &extents.x1, &extents.y1, &extents.x2, &extents.y2);
    }
};

/// A data structure for holding a path. This data structure serves as the
/// return value for `cr.copyPath()` and `cr.copyPathFlat()` as well the
/// input value for `cr.appendPath()`.
///
/// See `PathData` for hints on how to iterate over the actual data within the
/// path.
///
/// The `num_data` field gives the number of elements in the data array. This
/// number is larger than the number of independent path portions (defined in
/// cairo.PathData.Type), since the data includes both headers and coordinates
/// for each portion.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-path-t)
pub const Path = extern struct {
    /// the current error status
    status: Status,
    /// the elements in the path
    data: [*c]PathData,
    /// the number of elements in the data array
    num_data: c_int,

    /// Immediately releases all memory associated with `path`. After a call to
    /// `path.destroy()` the path pointer is no longer valid and should not be
    /// used further.
    ///
    /// **Note:** `path.destroy()` should only be called with a pointer to a
    /// `cairo.Path` returned by a cairo function. Any path that is created
    /// manually (ie. outside of cairo) should be destroyed manually as well.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-path-destroy)
    pub fn destroy(self: *Path) void {
        c.cairo_path_destroy(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// A convenience function that returns `cairo.Path`'s `data` as a slice.
    pub fn items(self: *Path) []PathData {
        return self.data[0..@intCast(self.num_data)];
    }

    pub const Iterator = struct {
        buffer: []PathData,
        index: usize,

        const resultT = struct { h_type: PathData.Type, points: []Point };
        // TODO: destructure it on new Zig version

        pub fn next(self: *Iterator) ?resultT {
            const result = self.peek() orelse return null;
            self.index += result.points.len + 1;
            return result;
        }

        pub fn peek(self: *Iterator) ?resultT {
            if (self.index >= self.buffer.len) return null;
            const end: usize = @intCast(self.buffer[self.index].header.length);
            return .{
                .h_type = self.buffer[self.index].header.h_type,
                .points = @ptrCast(self.buffer[self.index..][1..end]),
            };
        }

        pub fn reset(self: *Iterator) void {
            self.index = 0;
        }
    };

    pub fn iterator(self: *Path) Iterator {
        return .{
            .buffer = self.items(),
            .index = 0,
        };
    }
};

/// `PathData` is used to represent the path data inside a `Path`.
///
/// The data structure is designed to try to balance the demands of efficiency
/// and ease-of-use. A path is represented as an array of `PathData`, which is
/// a union of headers and points.
///
/// Each portion of the path is represented by one or more elements in the
/// array, (one header followed by 0 or more points). The length value of the
/// header is the number of array elements for the current portion including
/// the header, (ie. length == 1 + # of points), and where the number of points
/// for each element type is as follows:
/// ```
/// .MoveTo:     1 point
/// .LineTo:     1 point
/// .CurveTo:    3 points
/// .ClosePath:  0 points
/// ```
/// The semantics and ordering of the coordinate values are consistent with
/// `cr.moveTo()`, `cr.lineTo()`, `cr.curveTo()`, and `cr.closePath()`.
///
/// `cairo.Path` has an `Iterator` that makes handling it more user-friendly,
/// here is sample code:
/// ```zig
/// const path = try context.copyPath();
/// defer path.destroy();
/// var it = path.iterator();
///
/// while (it.next()) |item| {
///     switch (item.h_type) {
///         .MoveTo => doMoveToThigs(item.points[1].x, item.points[1].y),
///         .LineTo => doLineToThigs(item.points[1].x, item.points[1].y),
///         .CurveTo => doCurveToThigs(
///             item.points[1].x, item.points[1].y,
///             item.points[2].x, item.points[2].y,
///             item.points[3].x, item.points[3].y,
///         ),
///         .ClosePath => doClosePathThings(),
///     }
/// }
/// ```
/// **NOTE:** As of cairo 1.4, cairo does not mind if there are more elements
/// in a portion of the path than needed. Such elements can be used by users of
/// the cairo API to hold extra values in the path data structure. For this
/// reason, it is recommended that applications always use `data.header.length`
/// to iterate over the path data, instead of hardcoding the number of elements
/// for each element type.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-path-data-t)
pub const PathData = extern union {
    header: Header,
    point: Point,

    pub const Header = extern struct { h_type: PathData.Type, length: c_int };

    /// `cairo.PathData.Type` is used to describe the type of one portion of a
    /// path when represented as a `cairo.Path`. See `cairo.PathData` for
    /// details.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Paths.html#cairo-path-data-type-t)
    pub const Type = enum(c_uint) {
        /// A move-to operation
        MoveTo,
        /// A line-to operation
        LineTo,
        /// A curve-to operation
        CurveTo,
        /// A close-path operation
        ClosePath,
    };
};
