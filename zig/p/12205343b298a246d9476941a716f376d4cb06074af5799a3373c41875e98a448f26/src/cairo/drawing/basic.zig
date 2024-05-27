const std = @import("std");

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Context = cairo.Context;
const RectangleList = cairo.RectangleList;

const Surface = cairo.Surface;

const Antialias = cairo.Antialias;
const Content = cairo.Content;
const FillRule = Context.FillRule;
const LineCap = Context.LineCap;
const LineJoin = Context.LineJoin;
const Operator = Context.Operator;
const Status = cairo.Status;
const CairoError = cairo.CairoError;

const Pattern = cairo.Pattern;
const SurfacePattern = cairo.SurfacePattern;

const UserDataKey = cairo.UserDataKey;
const DestroyFn = cairo.DestroyFn;
const Point = cairo.Point;
const ExtentsRectangle = cairo.ExtentsRectangle;

pub const Mixin = struct {
    /// Creates a new `cairo.Context` with all graphics state parameters set to
    /// default values and with target as a target surface. The target surface
    /// should be constructed with a backend-specific function such as
    /// `cairo.ImageSurface.create()` (or any other
    /// `cairo.*Backend*Surface.create()` variant).
    ///
    /// This function references `target`, so you can immediately call
    /// `target.destroy()` on it if you don't need to maintain a separate
    /// reference to it.
    ///
    /// **Returns**
    ///
    /// a newly allocated `cairo.Context`. If memory cannot be allocated, an
    /// `error.OutOfMemory` will be raised. If you attempt to target a surface
    /// which does not support writing then an `error.WriteError` will be
    /// raised. You can use this object normally, but no drawing will be done.
    ///
    /// **NOTE**: The caller owns the created context and should call
    /// `cr.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const cr = try cairo.Context.create(surface);
    /// defer cr.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-create)
    pub fn create(target: *Surface) CairoError!*Context {
        const cr = c.cairo_create(target).?;
        try cr.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), cr);
        return cr;
    }

    /// Increases the reference count on context by one. This prevents context
    /// from being destroyed until a matching call to `cr.destroy()` is made.
    ///
    /// Use `cr.getReferenceCount()` to get the number of references to a
    /// `cairo.Context`.
    ///
    /// **Returns**
    ///
    /// the referenced `cairo.Context`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-reference)
    pub fn reference(self: *Context) *Context {
        if (safety.tracing) safety.reference(@returnAddress(), self);
        return c.cairo_reference(self).?;
    }

    /// Decreases the reference count on context by one. If the result is zero,
    /// then `self` and all associated resources are freed. See
    /// `cairo.Context.reference()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-destroy)
    pub fn destroy(self: *Context) void {
        c.cairo_destroy(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Checks whether an error has previously occurred for this context.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-status)
    pub fn status(self: *Context) Status {
        return c.cairo_status(self);
    }

    /// Makes a copy of the current state of `self` and saves it on an internal
    /// stack of saved states for `self`. When `.restore()` is called, `self`
    /// will be restored to the saved state. Multiple calls to `cr.save()` and
    /// `cr.restore()` can be nested; each call to `.restore()` restores the
    /// state from the matching paired `.save()`.
    ///
    /// It isn't necessary to clear all saved states before a `cairo.Context`
    /// is freed. If the reference count of a `cairo.Context` drops to zero in
    /// response to a call to `cr.destroy()`, any saved states will be freed
    /// along with the `cairo.Context`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-save)
    pub fn save(self: *Context) void {
        c.cairo_save(self);
    }

    /// Restores `self` to the state saved by a preceding call to `cr.save()`
    /// and removes that state from the stack of saved states.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-restore)
    pub fn restore(self: *Context) void {
        c.cairo_restore(self);
    }

    /// Gets the target surface for the cairo context as passed to
    /// `cairo.Context.create()`.
    ///
    /// **Returns**
    ///
    /// the target surface. This object is owned by cairo. To keep a reference
    /// to it, you must call `target.reference()` on it. This function can
    /// return error if `self` is already in an error state.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-target)
    pub fn getTarget(self: *Context) CairoError!*Surface {
        var target = c.cairo_get_target(self).?;
        try target.status().toErr();
        return target;
    }

    /// Temporarily redirects drawing to an intermediate surface known as a
    /// group. The redirection lasts until the group is completed by a call to
    /// `cr.popGroup()` or `cr.popGroupToSource()`. These calls provide the
    /// result of any drawing to the group as a pattern, (either as an explicit
    /// object, or set as the source pattern).
    ///
    /// This group functionality can be convenient for performing intermediate
    /// compositing. One common use of a group is to render objects as opaque
    /// within the group, (so that they occlude each other), and then blend the
    /// result with translucence onto the destination.
    ///
    /// Groups can be nested arbitrarily deep by making balanced calls to
    /// `cr.pushGroup()`/`cr.popGroup()`. Each call pushes/pops the new
    /// target group onto/from a stack.
    ///
    /// The `cr.pushGroup()` function calls `cr.save()` so that any changes
    /// to the graphics state will not be visible outside the group, (the
    /// `popGroup` functions call `cr.restore()`).
    ///
    /// By default the intermediate group will have a content type of
    /// `.ColorAlpha`. Other content types can be chosen for the group by using
    /// `cr.pushGroupWithContent()` instead.
    ///
    /// As an example, here is how one might fill and stroke a path with
    /// translucence, but without any portion of the fill being visible under
    /// the stroke:
    /// ```zig
    /// cr.pushGroup();
    /// cr.setSource(fillPattern);
    /// cr.fillPreserve();
    /// cr.setSource(strokePattern);
    /// cr.stroke();
    /// cr.popGroupToSource();
    /// cr.paintWithAlpha(alpha);
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-push-group)
    pub fn pushGroup(self: *Context) void {
        c.cairo_push_group(self);
    }

    /// Temporarily redirects drawing to an intermediate surface known as a
    /// group. The redirection lasts until the group is completed by a call to
    /// `cr.popGroup()` or `cr.popGroupToSource()`. These calls provide the
    /// result of any drawing to the group as a pattern, (either as an explicit
    /// object, or set as the source pattern).
    ///
    /// The group will have a content type of `content`. The ability to control
    /// this content type is the only distinction between this function and
    /// `cr.pushGroup()` which you should see for a more detailed description
    /// of group rendering.
    ///
    /// **Parameters**
    /// - `content`: a `cairo.Content` indicating the type of group that will
    /// be created
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-push-group-with-content)
    pub fn pushGroupWithContent(self: *Context, content: Content) void {
        c.cairo_push_group_with_content(self, content);
    }

    /// Terminates the redirection begun by a call to `cr.pushGroup()` or
    /// `cr.pushGroupWithContent()` and returns a new pattern containing the
    /// results of all drawing operations performed to the group.
    ///
    /// The `cr.popGroup()` function calls `cr.restore()`, (balancing a call to
    /// `cr.save()` by the `pushGroup` function), so that any changes to the
    /// graphics state will not be visible outside the group.
    ///
    /// **Returns**
    ///
    /// a newly created (surface) pattern containing the results of all drawing
    /// operations performed to the group.
    ///
    /// **NOTE**: The caller owns the created patern and should call
    /// `patern.destroy()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const pattern = cr.popGroup();
    /// defer pattern.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group)
    pub fn popGroup(self: *Context) *SurfacePattern {
        const pattern = c.cairo_pop_group(self).?;
        if (safety.tracing) safety.markForLeakDetection(@returnAddress(), pattern) catch |e| std.debug.panic("{any}", .{e});
        return pattern;
    }

    /// Terminates the redirection begun by a call to `cr.pushGroup()` or
    /// `cr.pushGroupWithContent()` and installs the resulting pattern as the
    /// source pattern in the given cairo context.
    ///
    /// The behavior of this function is equivalent to the sequence of
    /// operations:
    /// ```zig
    /// const group = cr.popGroup();
    /// cr.setSource(group);
    /// group.destroy();
    /// ```
    /// but is more convenient as their is no need for a variable to store the
    /// short-lived pointer to the pattern.
    ///
    /// The `cr.popGroup()` function calls `cr.restore()`, (balancing a call to
    /// `cr.save()` by the `pushGroup` function), so that any changes to the
    /// graphics state will not be visible outside the group.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group-to-source)
    pub fn popGroupToSource(self: *Context) void {
        c.cairo_pop_group_to_source(self);
    }

    /// Gets the current destination surface for the context. This is either
    /// the original target surface as passed to `cairo.Context.create()` or
    /// the target surface for the current group as started by the most recent
    /// call to `cr.pushGroup()` or `cr.pushGroupWithContent()`.
    ///
    /// **Returns**
    ///
    /// the target surface. This object is owned by cairo. To keep a reference
    /// to it, you must call `target.reference()` on it. This function can
    /// return error if `self` is already in an error state.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-group-target)
    pub fn getGroupTarget(self: *Context) CairoError!*Surface {
        const surface = c.cairo_get_group_target(self).?;
        try surface.status().toErr();
        return surface;
    }

    /// Sets the source pattern within `self` to an opaque color. This opaque
    /// color will then be used for any subsequent drawing operation until a
    /// new source pattern is set.
    ///
    /// The color components are floating point numbers in the range 0 to 1.
    /// If the values passed in are outside that range, they will be clamped.
    ///
    /// The default source pattern is opaque black, (that is, it is equivalent
    /// to `cr.setSourceRgb(0.0, 0.0, 0.0)`).
    ///
    /// **Parameters**
    /// - `red`: red component of color
    /// - `green`: green component of color
    /// - `blue`: blue component of color
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgb)
    pub fn setSourceRgb(self: *Context, red: f64, green: f64, blue: f64) void {
        c.cairo_set_source_rgb(self, red, green, blue);
    }

    /// Sets the source pattern within `self` to a translucent color. This
    /// color will then be used for any subsequent drawing operation until a
    /// new source pattern is set.
    ///
    /// The color and alpha components are floating point numbers in the range
    /// 0 to 1. If the values passed in are outside that range, they will be
    /// clamped.
    ///
    /// The default source pattern is opaque black, (that is, it is equivalent
    /// to `cr.setSourceRgba(0.0, 0.0, 0.0, 1.0)`).
    ///
    /// **Parameters**
    /// - `red`: red component of color
    /// - `green`: green component of color
    /// - `blue`: blue component of color
    /// - `alpha`: alpha component of color
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgba)
    pub fn setSourceRgba(self: *Context, red: f64, green: f64, blue: f64, alpha: f64) void {
        c.cairo_set_source_rgba(self, red, green, blue, alpha);
    }

    /// Sets the source pattern within `self` to `source`. This pattern will
    /// then be used for any subsequent drawing operation until a new source
    /// pattern is set.
    ///
    /// Note: The pattern's transformation matrix will be locked to the user
    /// space in effect at the time of c.cairo_set_source(). This means that
    /// further modifications of the current transformation matrix will not
    /// affect the source pattern. See `cairo.Pattern.setMatrix()`.
    ///
    /// The default source pattern is a solid pattern that is opaque black,
    /// (that is, it is equivalent to `cr.setSourceRgb(0.0, 0.0, 0.0)`).
    ///
    /// **Parameters**
    /// - `source`: a `cairo.Pattern` to be used as the source for subsequent
    /// drawing operations. **HINT**: use `.asPattern()` on a specific
    /// `pattern` to cast it into `cairo.Pattern` object.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-source)
    pub fn setSource(self: *Context, source: *Pattern) void {
        c.cairo_set_source(self, source);
    }

    /// This is a convenience function for creating a pattern from `surface`
    /// and setting it as the source in `self` with `.setSource()`.
    ///
    /// The `x` and `y` parameters give the user-space coordinate at which the
    /// surface origin should appear. (The surface origin is its upper-left
    /// corner before any transformation has been applied.) The `x` and `y`
    /// parameters are negated and then set as translation values in the
    /// pattern matrix.
    ///
    /// Other than the initial translation pattern matrix, as described above,
    /// all other pattern attributes, (such as its extend mode), are set to the
    /// default values as in `cairo.SurfacePattern.createFor()`. The resulting
    /// pattern can be queried with `cr.getSource()` so that these attributes
    /// can be modified if desired, (eg. to create a repeating pattern with
    /// `pattern.setExtend()`).
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-surface)
    pub fn setSourceSurface(self: *Context, surface: *Surface, x: f64, y: f64) void {
        c.cairo_set_source_surface(self, surface, x, y);
    }

    /// Gets the current source pattern for `self`.
    ///
    /// **Returns**
    ///
    /// the current source pattern. This object is owned by cairo. To keep a
    /// reference to it, you must call `pattern.reference()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-source)
    pub fn getSource(self: *Context) *Pattern {
        return c.cairo_get_source(self).?;
    }

    /// Set the antialiasing mode of the rasterizer used for drawing shapes.
    /// This value is a hint, and a particular backend may or may not support
    /// a particular value. At the current time, no backend supports
    /// `.Subpixel` when drawing shapes.
    ///
    /// Note that this option does not affect text rendering, instead see
    /// c.cairo_font_options_set_antialias().
    ///
    /// **Parameters**
    /// - `antialias`: the new antialiasing mode
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-antialias)
    pub fn setAntialias(self: *Context, antialias: Antialias) void {
        // TODO: fix desc
        c.cairo_set_antialias(self, antialias);
    }

    /// Gets the current shape antialiasing mode, as set by
    /// `cr.setAntialias()`.
    ///
    /// **Returns**
    ///
    /// the current shape antialiasing mode.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-antialias)
    pub fn getAntialias(self: *Context) Antialias {
        return c.cairo_get_antialias(self);
    }

    /// Sets the dash pattern to be used by `cr.stroke()`. A dash pattern is
    /// specified by `dashes`, a slice of positive values. Each value provides
    /// the length of alternate "on" and "off" portions of the stroke. The
    /// `offset` specifies an offset into the pattern at which the stroke
    /// begins.
    ///
    /// Each "on" segment will have caps applied as if the segment were a
    /// separate sub-path. In particular, it is valid to use an "on" length of
    /// 0.0 with `cairo.Context.LineCap` `.Round` or `.Square` in order to
    /// distributed dots or squares along a path.
    ///
    /// Note: The length values are in user-space units as evaluated at the
    /// time of stroking. This is not necessarily the same as the user space
    /// at the time of `cr.setDash()`.
    ///
    /// If `dashes.len` is 0 dashing is disabled.
    ///
    /// If `dashes.len` is 1 a symmetric pattern is assumed with alternating on
    /// and off portions of the size specified by the single value in `dashes`.
    ///
    /// If any value in dashes is negative, or if all values are 0, then `self`
    /// will be put into an error state with a status of
    /// `cairo.Status.InvalidDash`.
    ///
    /// **Parameters**
    /// - `dashes`: a slice specifying alternate lengths of on and off stroke
    /// portions
    /// - `offset`: an offset into the dash pattern at which the stroke should
    /// start
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-dash)
    pub fn setDash(self: *Context, dashes: []const f64, offset: f64) void {
        c.cairo_set_dash(self, dashes.ptr, @intCast(dashes.len), offset);
    }

    /// This function returns the length of the dash array in `self` (0 if
    /// dashing is not currently in effect).
    ///
    /// See also `cairo.Context.setDash()` and `cairo.Context.getDash()`.
    ///
    /// **Returns**
    ///
    /// the length of the dash array, or 0 if no dash array set.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash-count)
    pub fn getDashCount(self: *Context) usize {
        return @intCast(c.cairo_get_dash_count(self));
    }

    /// Gets the current dash array. If not `null`, dashes should be big enough
    /// to hold at least the number of values returned by `cr.getDashCount()`.
    ///
    /// **Parameters**
    /// - `dashes`: return value for the dash array, or `null`
    /// - `offset`: return value for the current dash offset, or `null`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash)
    pub fn getDash(self: *Context, dashes: ?[*]f64, offset: ?*f64) void {
        // TODO: think about return values
        c.cairo_get_dash(self, dashes, offset);
    }

    /// Set the current fill rule within the cairo context. The fill rule is
    /// used to determine which regions are inside or outside a complex
    /// (potentially self-intersecting) path. The current fill rule affects
    /// both `cr.fill()` and `cr.clip()`. See `cairo.Context.FillRule` for
    /// details on the semantics of each available fill rule.
    ///
    /// The default fill rule is `.Winding`.
    ///
    /// **Parameters**
    /// - `fill_rule`: a fill rule, specified as a `cairo.Context.FillRule`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-fill-rule)
    pub fn setFillRule(self: *Context, fill_rule: FillRule) void {
        c.cairo_set_fill_rule(self, fill_rule);
    }

    /// Gets the current fill rule, as set by `cr.setFillRule()`.
    ///
    /// **Returns**
    ///
    /// the current fill rule.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-fill-rule)
    pub fn getFillRule(self: *Context) FillRule {
        return c.cairo_get_fill_rule(self);
    }

    /// Sets the current line cap style within the cairo context. See
    /// `cairo.Context.LineCap` for details about how the available line cap
    /// styles are drawn.
    ///
    /// As with the other stroke parameters, the current line cap style is
    /// examined by `cr.stroke()`, `cr.strokeExtents()`, and
    /// `cr.strokeToPath()`, but does not have any effect during path
    /// construction.
    ///
    /// The default line cap style is `.Butt`.
    ///
    /// **Parameters**
    /// - `line_cap`: a line cap style
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-cap)
    pub fn setLineCap(self: *Context, line_cap: LineCap) void {
        c.cairo_set_line_cap(self, line_cap);
    }

    /// Gets the current line cap style, as set by `cr.setLineCap()`.
    ///
    /// **Returns**
    ///
    /// the current line cap style.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-cap)
    pub fn getLineCap(self: *Context) LineCap {
        return c.cairo_get_line_cap(self);
    }

    /// Sets the current line join style within the cairo context. See
    /// `cairo.Context.LineJoin` for details about how the available line join
    /// styles are drawn.
    ///
    /// As with the other stroke parameters, the current line join style is
    /// examined by `cr.stroke()`, `cr.strokeExtents()`, and
    /// `cr.strokeToPath()`, but does not have any effect during path
    /// construction.
    ///
    /// The default line join style is `.Miter`.
    ///
    /// **Parameters**
    /// - `line_join`: a line join style
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-join)
    pub fn setLineJoin(self: *Context, line_join: LineJoin) void {
        c.cairo_set_line_join(self, line_join);
    }

    /// Gets the current line join style, as set by `cr.setLineJoin()`.
    ///
    /// **Returns**
    ///
    /// the current line join style.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-join)
    pub fn getLineJoin(self: *Context) LineJoin {
        return c.cairo_get_line_join(self);
    }

    /// Sets the current line width within the cairo context. The line width
    /// value specifies the diameter of a pen that is circular in user space,
    /// (though device-space pen may be an ellipse in general due to
    /// scaling/shear/rotation of the CTM).
    ///
    /// Note: When the description above refers to user space and CTM it refers
    /// to the user space and CTM in effect at the time of the stroking
    /// operation, not the user space and CTM in effect at the time of the call
    /// to `cr.setLineWidth()`. The simplest usage makes both of these spaces
    /// identical. That is, if there is no change to the CTM between a call to
    /// `cr.setLineWidth()` and the stroking operation, then one can just pass
    /// user-space values to `cr.setLineWidth()` and ignore this note.
    ///
    /// As with the other stroke parameters, the current line width is
    /// examined by `cr.stroke()`, `cr.strokeExtents()`, and
    /// `cr.strokeToPath()`, but does not have any effect during path
    /// construction.
    ///
    /// The default line width value is 2.0.
    ///
    /// **Parameters**
    /// - `line_width`: a line width
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-width)
    pub fn setLineWidth(self: *Context, line_width: f64) void {
        c.cairo_set_line_width(self, line_width);
    }

    /// This function returns the current line width value exactly as set by
    /// `cr.setLineWidth()`. Note that the value is unchanged even if the CTM
    /// has changed between the calls to `cr.setLineWidth()` and
    /// `cr.getLineWidth()`.
    ///
    /// **Returns**
    ///
    /// the current line width.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-width)
    pub fn getLineWidth(self: *Context) f64 {
        return c.cairo_get_line_width(self);
    }

    /// Sets the current miter limit within the cairo context.
    ///
    /// If the current line join style is set to `.Miter` (see
    /// `cairo.Context.setLineJoin()`), the miter limit is used to determine
    /// whether the lines should be joined with a bevel instead of a miter.
    /// Cairo divides the length of the miter by the line width. If the result
    /// is greater than the miter limit, the style is converted to a bevel.
    ///
    /// As with the other stroke parameters, the current line miter limit is
    /// examined by `cr.stroke()`, `cr.strokeExtents()`, and
    /// `cr.strokeToPath()`, but does not have any effect during path
    /// construction.
    ///
    /// The default miter limit value is 10.0, which will convert joins with
    /// interior angles less than 11 degrees to bevels instead of miters. For
    /// reference, a miter limit of 2.0 makes the miter cutoff at 60 degrees,
    /// and a miter limit of 1.414 makes the cutoff at 90 degrees.
    ///
    /// A miter limit for a desired angle can be computed as: miter limit =
    /// 1/sin(angle/2)
    ///
    /// **Parameters**
    /// - `limit`: miter limit to set
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit)
    pub fn setMiterLimit(self: *Context, limit: f64) void {
        c.cairo_set_miter_limit(self, limit);
    }

    /// Gets the current miter limit, as set by `cr.setMiterLimit()`.
    ///
    /// **Returns**
    ///
    /// the current miter limit.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-miter-limit)
    pub fn getMiterLimit(self: *Context) f64 {
        return c.cairo_get_miter_limit(self);
    }

    /// Sets the compositing operator to be used for all drawing operations.
    /// See `cairo.Context.Operator` for details on the semantics of each
    /// available compositing operator.
    ///
    /// The default operator is `.Over`.
    ///
    /// **Parameters**
    /// - `op`: a compositing operator, specified as a `cairo.Context.Operator`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-operator)
    pub fn setOperator(self: *Context, op: Operator) void {
        c.cairo_set_operator(self, op);
    }

    /// Gets the current compositing operator for a cairo context.
    ///
    /// **Returns**
    ///
    /// the current compositing operator.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-operator)
    pub fn getOperator(self: *Context) Operator {
        return c.cairo_get_operator(self);
    }

    /// Sets the tolerance used when converting paths into trapezoids. Curved
    /// segments of the path will be subdivided until the maximum deviation
    /// between the original path and the polygonal approximation is less than
    /// `tolerance`. The default value is 0.1. A larger value will give better
    /// performance, a smaller value, better appearance. (Reducing the value
    /// from the default value of 0.1 is unlikely to improve appearance
    /// significantly.) The accuracy of paths within Cairo is limited by the
    /// precision of its internal arithmetic, and the prescribed `tolerance` is
    /// restricted to the smallest representable internal value.
    ///
    /// **Parameters**
    /// - `tolerance`: the tolerance, in device units (typically pixels)
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-tolerance)
    pub fn setTolerance(self: *Context, tolerance: f64) void {
        c.cairo_set_tolerance(self, tolerance);
    }

    /// Gets the current tolerance value, as set by `cr.setTolerance()`.
    ///
    /// **Returns**
    ///
    /// the current tolerance value.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-tolerance)
    pub fn getTolerance(self: *Context) f64 {
        return c.cairo_get_tolerance(self);
    }

    /// Establishes a new clip region by intersecting the current clip region
    /// with the current path as it would be filled by `cr.fill()` and
    /// according to the current fill rule (see `cairo.Context.setFillRule()`).
    ///
    /// After `cr.clip()`, the current path will be cleared from the cairo
    /// context.
    ///
    /// The current clip region affects all drawing operations by effectively
    /// masking out any changes to the surface that are outside the current
    /// clip region.
    ///
    /// Calling `cr.clip()` can only make the clip region smaller, never
    /// larger. But the current clip is part of the graphics state, so a
    /// temporary restriction of the clip region can be achieved by calling
    /// `cr.clip()` within a `cr.save()`/`cr.restore()` pair. The only other
    /// means of increasing the size of the clip region is `cr.resetClip()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-clip)
    pub fn clip(self: *Context) void {
        c.cairo_clip(self);
    }

    /// Establishes a new clip region by intersecting the current clip region
    /// with the current path as it would be filled by `cr.fill()` and
    /// according to the current fill rule (see `cairo.Context.setFillRule()`).
    ///
    /// Unlike `cr.clip()`, `cr.clipPreserve()` preserves the path within the
    /// cairo context.
    ///
    /// The current clip region affects all drawing operations by effectively
    /// masking out any changes to the surface that are outside the current
    /// clip region.
    ///
    /// Calling `cr.clipPreserve()` can only make the clip region smaller,
    /// never larger. But the current clip is part of the graphics state, so a
    /// temporary restriction of the clip region can be achieved by calling
    /// `cr.clipPreserve()` within a `cr.save()`/`cr.restore()` pair. The
    /// only other means of increasing the size of the clip region is
    /// `cr.resetClip()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-clip-preserve)
    pub fn clipPreserve(self: *Context) void {
        c.cairo_clip_preserve(self);
    }

    /// Computes a bounding box in user coordinates covering the area inside
    /// the current clip.
    ///
    /// **Parameters**
    /// - `extents`: resulting extents
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-clip-extents)
    pub fn clipExtents(self: *Context, extents: *ExtentsRectangle) void {
        c.cairo_clip_extents(self, &extents.x1, &extents.y1, &extents.x2, &extents.y2);
    }

    /// Tests whether the given point is inside the area that would be visible
    /// through the current clip, i.e. the area that would be filled by a
    /// `cr.paint()` operation.
    ///
    /// See `cairo.Context.clip()`, and `cairo.Context.clipPreserve()`.
    ///
    /// **Parameters**
    /// - `point`: point to test
    ///
    /// **Returns**
    ///
    /// `true` if the point is inside, or `false` if outside.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-in-clip)
    pub fn inClip(self: *Context, point: Point) bool {
        return c.cairo_in_clip(self, point.x, point.y) != 0;
    }

    /// Reset the current clip region to its original, unrestricted state. That
    /// is, set the clip region to an infinitely large shape containing the
    /// target surface. Equivalently, if infinity is too hard to grasp, one can
    /// imagine the clip region being reset to the exact bounds of the target
    /// surface.
    ///
    /// Note that code meant to be reusable should not call `cr.resetClip()` as
    /// it will cause results unexpected by higher-level code which calls
    /// `cr.clip()`. Consider using `cr.save()` and `cr.restore()` around
    /// `cr.clip()` as a more robust means of temporarily restricting the clip
    /// region.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-reset-clip)
    pub fn resetClip(self: *Context) void {
        c.cairo_reset_clip(self);
    }

    /// Gets the current clip region as a list of rectangles in user
    /// coordinates. Never returns `null`.
    ///
    /// The status in the list may be `cairo.Status.ClipNotRepresentable` to
    /// indicate that the clip region cannot be represented as a list of
    /// user-space rectangles. The status may have other values to indicate
    /// other errors.
    ///
    /// **Returns**
    ///
    /// the current clip region as a list of rectangles in user coordinates,
    /// which should be destroyed using `rectangleList.destroy()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-copy-clip-rectangle-list)
    pub fn copyClipRectangleList(self: *Context) CairoError!*RectangleList {
        const list: *RectangleList = c.cairo_copy_clip_rectangle_list(self).?;
        try list.status.toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), list);
        return list;
    }

    /// A drawing operator that fills the current path according to the current
    /// fill rule, (each sub-path is implicitly closed before being filled).
    /// After `cr.fill()`, the current path will be cleared from the cairo
    /// context. See `cairo.Context.setFillRule()` and `cr.fillPreserve()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-fill)
    pub fn fill(self: *Context) void {
        c.cairo_fill(self);
    }

    /// A drawing operator that fills the current path according to the current
    /// fill rule, (each sub-path is implicitly closed before being filled).
    /// Unlike `cr.fill()`, `cr.fillPreserve()` preserves the path within the
    /// cairo context.
    ///
    /// See `cairo.Context.setFillRule()` and `cairo.Context.fill()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-fill-preserve)
    pub fn fillPreserve(self: *Context) void {
        c.cairo_fill_preserve(self);
    }

    /// Computes a bounding box in user coordinates covering the area that
    /// would be affected, (the "inked" area), by a `cr.fill()` operation
    /// given the current path and fill parameters. If the current path is
    /// empty, returns an empty rectangle `((0,0), (0,0))`. Surface
    /// dimensions and clipping are not taken into account.
    ///
    /// Contrast with `cairo.Context.pathExtents()`, which is similar, but
    /// returns non-zero extents for some paths with no inked area, (such as a
    /// simple line segment).
    ///
    /// Note that `cr.fillExtents()` must necessarily do more work to compute
    /// the precise inked areas in light of the fill rule, so
    /// `cairo.Context.pathExtents()` may be more desirable for sake of
    /// performance if the non-inked path extents are desired.
    ///
    /// See `cairo.Context.fill()`, `cairo.Context.setFillRule()` and
    /// `cairo.Context.fillPreserve().`
    ///
    /// **Parameters**
    /// - `extents`: the resulting extents
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-fill-extents)
    pub fn fillExtents(self: *Context, extents: *ExtentsRectangle) void {
        c.cairo_fill_extents(self, &extents.x1, &extents.y1, &extents.x2, &extents.y2);
    }

    /// Tests whether the given point is inside the area that would be affected
    /// by a `cr.fill()` operation given the current path and filling
    /// parameters. Surface dimensions and clipping are not taken into account.
    ///
    /// See `cairo.Context.fill()`, `cairo.Context.setFillRule()` and
    /// `cairo.Context.fillPreserve().`
    ///
    /// **Parameters**
    /// - `point`: point to test
    ///
    /// **Returns**
    ///
    /// `true` if the point is inside, or `false` if outside.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-in-fill)
    pub fn inFill(self: *Context, point: Point) bool {
        return c.cairo_in_fill(self, point.x, point.y) != 0;
    }

    /// A drawing operator that paints the current source using the alpha
    /// channel of pattern as a mask. (Opaque areas of pattern are painted
    /// with the source, transparent areas are not painted.)
    ///
    /// **Parameters**
    /// - `pattern`: a `cairo.Pattern`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-mask)
    pub fn mask(self: *Context, pattern: *Pattern) void {
        c.cairo_mask(self, pattern);
    }

    /// A drawing operator that paints the current source using the alpha
    /// channel of `surface` as a mask. (Opaque areas of `surface` are painted
    /// with the source, transparent areas are not painted.)
    ///
    /// **Parameters**
    /// - `surface`: a `cairo.Surface`
    /// - `surface_x`: X coordinate at which to place the origin of `surface`
    /// - `surface_y`: Y coordinate at which to place the origin of `surface`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-mask-surface)
    pub fn maskSurface(self: *Context, surface: *Surface, surface_x: f64, surface_y: f64) void {
        c.cairo_mask_surface(self, surface, surface_x, surface_y);
    }

    /// A drawing operator that paints the current source everywhere within the
    /// current clip region.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-paint)
    pub fn paint(self: *Context) void {
        c.cairo_paint(self);
    }

    /// A drawing operator that paints the current source everywhere within the
    /// current clip region using a mask of constant alpha value `alpha`. The
    /// effect is similar to c.cairo_paint(), but the drawing is faded out using
    /// the alpha value.
    ///
    /// **Parameters**
    /// - `alpha`: alpha value, between 0 (transparent) and 1 (opaque)
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-paint-with-alpha)
    pub fn paintWithAlpha(self: *Context, alpha: f64) void {
        c.cairo_paint_with_alpha(self, alpha);
    }

    /// A drawing operator that strokes the current path according to the
    /// current line width, line join, line cap, and dash settings. After
    /// `cr.stroke()`, the current path will be cleared from the cairo
    /// context.
    ///
    /// See `cairo.Context.setLineWidth()`, `cairo.Context.setLinejoin()`,
    /// `cairo.Context.setLineCap()`, `cairo.Context.setDash()`, and
    /// `cairo.Context.strokePreserve()`.
    ///
    /// Note: Degenerate segments and sub-paths are treated specially and
    /// provide a useful result. These can result in two different situations:
    /// 1. Zero-length "on" segments set in `cr.setDash()`. If the cap style is
    /// `.Round` or `.Square` then these segments will be drawn as circular
    /// dots or squares respectively. In the case of `.Square`, the orientation
    /// of the squares is determined by the direction of the underlying path.
    /// 2. A sub-path created by `cr.moveTo()` followed by either a
    /// `cr.closePath()` or one or more calls to `cr.lineTo()` to the same
    /// coordinate as the `cr.moveTo()`. If the cap style is `.Round` then
    /// these sub-paths will be drawn as circular dots. Note that in the case
    /// of `.Square` a degenerate sub-path will not be drawn at all, (since the
    /// correct orientation is indeterminate).
    ///
    /// In no case will a cap style of `.Butt` cause anything to be drawn in
    /// the case of either degenerate segments or sub-paths.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-stroke)
    pub fn stroke(self: *Context) void {
        c.cairo_stroke(self);
    }

    /// A drawing operator that strokes the current path according to the
    /// current line width, line join, line cap, and dash settings. Unlike
    /// `cr.stroke()`, `cr.strokePreserve()` preserves the path within the
    /// cairo context.
    ///
    /// See `cairo.Context.setLineWidth()`, `cairo.Context.setLinejoin()`,
    /// `cairo.Context.setLineCap()`, `cairo.Context.setDash()`, and
    /// `cairo.Context.stroke()`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-preserve)
    pub fn strokePreserve(self: *Context) void {
        c.cairo_stroke_preserve(self);
    }

    /// Computes a bounding box in user coordinates covering the area that
    /// would be affected, (the "inked" area), by a `cr.stroke()` operation
    /// given the current path and stroke parameters. If the current path is
    /// empty, returns an empty rectangle `((0,0), (0,0))`. Surface dimensions
    /// and clipping are not taken into account.
    ///
    /// Note that if the line width is set to exactly zero, then
    /// `cr.strokeExtents()` will return an empty rectangle. Contrast with
    /// `cairo.Context.pathExtents()` which can be used to compute the
    /// non-empty bounds as the line width approaches zero.
    ///
    /// Note that `cr.strokeExtents()` must necessarily do more work to
    /// compute the precise inked areas in light of the stroke parameters, so
    /// `cairo.Context.pathExtents()` may be more desirable for sake of
    /// performance if non-inked path extents are desired.
    ///
    /// See `cairo.Context.stroke()`, `cairo.Context.setLineWidth()`,
    /// `cairo.Context.setLinejoin()`, `cairo.Context.setLineCap()`,
    /// `cairo.Context.setDash()` and `cairo.Context.strokePreserve()`.
    ///
    /// **Parameters**
    /// - `extents`: the resulting extents
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-extents)
    pub fn cairoStrokeExtents(self: *Context, extents: *ExtentsRectangle) void {
        c.cairo_stroke_extents(self, &extents.x1, &extents.y1, &extents.x2, &extents.y2);
    }

    /// Tests whether the given point is inside the area that would be affected
    /// by a `cr.stroke()` operation given the current path and stroking
    /// parameters. Surface dimensions and clipping are not taken into account.
    ///
    /// See `cairo.Context.stroke()`, `cairo.Context.setLineWidth()`,
    /// `cairo.Context.setLinejoin()`, `cairo.Context.setLineCap()`,
    /// `cairo.Context.setDash()` and `cairo.Context.strokePreserve()`.
    ///
    /// **Parameters**
    /// - `point`: point to test
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-in-stroke)
    pub fn inStroke(self: *Context, point: Point) bool {
        return c.cairo_in_stroke(self, point.x, point.y) != 0;
    }

    /// Emits the current page for backends that support multiple pages, but
    /// doesn't clear it, so, the contents of the current page will be retained
    /// for the next page too. Use `cr.showPage()` if you want to get an empty
    /// page after the emission.
    ///
    /// This is a convenience function that simply calls `surface.copyPage()`
    /// on `self`'s target.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-copy-page)
    pub fn copyPage(self: *Context) void {
        c.cairo_copy_page(self);
    }

    /// Emits and clears the current page for backends that support multiple
    /// pages. Use `cr.copyPage()` if you don't want to clear the page.
    ///
    /// This is a convenience function that simply calls `surface.showPage()`
    /// on `self`'s target.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-show-page)
    pub fn showPage(self: *Context) void {
        c.cairo_show_page(self);
    }

    /// Returns the current reference count of `self`.
    ///
    /// **Returns**
    ///
    /// the current reference count of `self`. If the object is a nil object, 0
    /// will be returned.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count)
    pub fn getReferenceCount(self: *Context) usize {
        return @intCast(c.cairo_get_reference_count(self));
    }

    /// Attach user data to `self`. To remove user data from a surface, call
    /// this function with the key that was used to set it and `null` for
    /// `data`.
    ///
    /// **Parameters**
    /// - `key`: the address of a `cairo.UserDataKey` to attach the user data
    /// to
    /// - `user_data`: the user data to attach to the `cairo.Context`
    /// - `destroyFn`: a `cairo.DestroyFn` which will be called when the
    /// `cairo.Context` is destroyed or when new user data is attached using
    /// the same key.
    ///
    /// The only possible error is `error.OutOfMemory`, which will be raised if
    /// a slot could not be allocated for the user data.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data)
    pub fn setUserData(self: *Context, key: *const UserDataKey, user_data: ?*anyopaque, destroyFn: DestroyFn) CairoError!void {
        try c.cairo_set_user_data(self, key, user_data, destroyFn).toErr();
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
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data)
    pub fn getUserData(self: *Context, key: *const UserDataKey) ?*anyopaque {
        return c.cairo_get_user_data(self, key);
    }
};
