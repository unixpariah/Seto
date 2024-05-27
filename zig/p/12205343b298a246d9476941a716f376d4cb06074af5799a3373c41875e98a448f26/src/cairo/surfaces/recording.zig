//! Recording Surfaces — Records all drawing operations

const cairo = @import("../../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const Mixin = @import("base.zig").Base;

const CairoError = cairo.CairoError;
const Content = cairo.Content;
const Rectangle = cairo.Rectangle;

/// A recording surface is a surface that records all drawing operations at the
/// highest level of the surface backend interface, (that is, the level of
/// paint, mask, stroke, fill, and showTextGlyphs). The recording surface can
/// then be "replayed" against any target surface by using it as a source
/// surface.
///
/// If you want to replay a surface so that the results in target will be
/// identical to the results that would have been obtained if the original
/// operations applied to the recording surface had instead been applied to the
/// target surface, you can use code like this:
/// ```zig
/// const context = cairo.Context.create(target);
/// context.setSourceSurface(recording_surface, 0.0, 0.0);
/// context.paint();
/// context.destroy();
/// ```
/// A recording surface is logically unbounded, i.e. it has no implicit
/// constraint on the size of the drawing surface. However, in practice this is
/// rarely useful as you wish to replay against a particular target surface
/// with known bounds. For this case, it is more efficient to specify the
/// target extents to the recording surface upon creation.
///
/// The recording phase of the recording surface is careful to snapshot all
/// necessary objects (paths, patterns, etc.), in order to achieve accurate
/// replay. The efficiency of the recording surface could be improved by
/// improving the implementation of snapshot for the various objects. For
/// example, it would be nice to have a copy-on-write implementation for
/// _cairo_surface_snapshot. (idk what that means)
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Recording-Surfaces.html)
pub const RecordingSurface = opaque {
    pub usingnamespace Mixin(@This());

    /// Creates a recording-surface which can be used to record all drawing
    /// operations at the highest level (that is, the level of paint, mask,
    /// stroke, fill and showTextGlyphs). The recording surface can then be
    /// "replayed" against any target surface by using it as a source to
    /// drawing operations.
    ///
    /// The recording phase of the recording surface is careful to snapshot all
    /// necessary objects (paths, patterns, etc.), in order to achieve accurate
    /// replay.
    ///
    /// **Parameters**
    /// - `content`: the content of the recording surface
    /// - `extents`:the extents to record in pixels, can be `null` to record
    /// unbounded operations.
    ///
    /// **Returns**
    ///
    /// a pointer to the newly created surface.
    ///
    /// **NOTE**: The caller owns the created surface and should call
    /// `surface.destroy()` when done with it. You can use idiomatic Zig
    /// pattern with `defer`:
    /// ```zig
    /// const surface = try cairo.RecordingSurface.create(.ColorAlpha, null);
    /// defer surface.destroy();
    /// ```
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-create)
    pub fn create(content: Content, extents: ?*const Rectangle) CairoError!*RecordingSurface {
        const surface = c.cairo_recording_surface_create(content, extents orelse null).?;
        try surface.status().toErr();
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), surface);
        return surface;
    }

    /// Measures the extents of the operations stored within the
    /// recording-surface. This is useful to compute the required size of an
    /// image surface (or equivalent) into which to replay the full sequence of
    /// drawing operations.
    ///
    /// **Parameters**
    /// - `x0`: the x-coordinate of the top-left of the ink bounding box
    /// - `y0`: the y-coordinate of the top-left of the ink bounding box
    /// - `width`: the width of the ink bounding box
    /// - `height`: the height of the ink bounding box
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-ink-extents)
    pub fn inkExtents(self: *RecordingSurface, x0: *f64, y0: *f64, width: *f64, height: *f64) void {
        c.cairo_recording_surface_ink_extents(self, x0, y0, width, height);
    }

    /// Get the extents of the recording-surface.
    ///
    /// **Parameters**
    /// - `extents`: the `cairo.Rectangle` to be assigned the extents
    ///
    /// **Returns**
    ///
    /// `true` if the surface is bounded, of recording type, and not in an
    /// error state, otherwise `false`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-get-extents)
    pub fn getExtents(self: *RecordingSurface, extents: *Rectangle) bool {
        return c.cairo_recording_surface_get_extents(self, extents) != 0;
    }
};
