const safety = @import("safety");
const pango = @import("../pango.zig");
const c = pango.c;

/// A `Matrix` specifies a transformation between user-space and device
/// coordinates.
///
/// The transformation is given by
/// ```zig
/// x_device = x_user * matrix.xx + y_user * matrix.xy + matrix.x0;
/// y_device = x_user * matrix.yx + y_user * matrix.yy + matrix.y0;
/// ```
pub const Matrix = extern struct {
    /// 1st component of the transformation matrix.
    xx: f64,
    /// 2nd component of the transformation matrix.
    xy: f64,
    /// 3rd component of the transformation matrix.
    yx: f64,
    /// 4th component of the transformation matrix.
    yy: f64,
    /// X translation.
    x0: f64,
    /// Y translation.
    y0: f64,

    /// Copies a `pango.Matrix`.
    ///
    /// **Returns**
    ///
    /// the newly allocated `pango.Matrix`.
    ///
    /// **NOTE**: The caller owns the created matrix and should call
    /// `matrix.free()` when done with it. You can use idiomatic Zig pattern
    /// with `defer`:
    /// ```zig
    /// const matrix = try another_matrix.copy();
    /// defer matrix.free();
    /// ```
    pub fn copy(self: *Matrix) !*Matrix {
        const ptr = c.pango_matrix_copy(self) orelse return error.NullPointer;
        if (safety.tracing) try safety.markForLeakDetection(@returnAddress(), ptr);
        return ptr;
    }

    /// Free a `pango.Matrix`.
    pub fn free(self: *Matrix) void {
        c.pango_matrix_free(self);
        if (safety.tracing) safety.destroy(self);
    }

    /// Changes the transformation represented by `self` to be the
    /// transformation given by first translating by (`tx`, `ty`) then applying
    /// the original transformation.
    ///
    /// **Parameters**
    /// - `tx`: amount to translate in the X direction
    /// - `ty`: amount to translate in the Y direction
    pub fn translate(self: *Matrix, tx: f64, ty: f64) void {
        c.pango_matrix_translate(self, tx, ty);
    }

    /// Changes the transformation represented by `self` to be the
    /// transformation given by first scaling by `sx` in the X direction and
    /// `sy` in the Y direction then applying the original transformation.
    ///
    /// **Parameters**
    /// - `scale_x`: amount to scale by in X direction
    /// - `scale_y`: amount to scale by in Y direction
    pub fn scale(self: *Matrix, scale_x: f64, scale_y: f64) void {
        c.pango_matrix_scale(self, scale_x, scale_y);
    }

    /// Changes the transformation represented by `self` to be the
    /// transformation given by first rotating by `degrees` degrees
    /// counter-clockwise then applying the original transformation.
    ///
    /// **Parameters**
    /// - `degrees`: degrees to rotate counter-clockwise
    pub fn rotate(self: *Matrix, degrees: f64) void {
        c.pango_matrix_rotate(self, degrees);
    }

    /// Changes the transformation represented by `self` to be the
    /// transformation given by first applying transformation given by
    /// `new_matrix` then applying the original transformation.
    ///
    /// **Parameters**
    /// - `new_matrix`: a `pango.Matrix`
    /// - `aboba`:
    pub fn concat(self: *Matrix, new_matrix: *const Matrix) void {
        c.pango_matrix_concat(self, new_matrix);
    }

    /// Transforms the point (`x`, `y`) by `self` matrix.
    ///
    /// **Parameters**
    /// - `x`: in/out X position
    /// - `y`: in/out Y position
    pub fn transformPoint(self: *const Matrix, x: *f64, y: *f64) void {
        c.pango_matrix_transform_point(self, x, y);
    }

    /// Transforms the distance vector (`dx`, `dy`) by `self` matrix.
    ///
    /// This is similar to `pango.Matrix.transformPoint()`, except that the
    /// translation components of the transformation are ignored. The
    /// calculation of the returned vector is as follows.
    /// ```zig
    /// dx2 = dx1 * xx + dy1 * xy;
    /// dy2 = dx1 * yx + dy1 * yy;
    /// ```
    /// Affine transformations are position invariant, so the same vector
    /// always transforms to the same vector. If (`x1`,`y1`) transforms to
    /// (`x2`,`y2`) then (`x1`+`dx1`,`y1`+`dy1`) will transform to
    /// (`x1`+`dx2`,`y1`+`dy2`) for all values of `x1` and `x2`.
    ///
    /// **Parameters**
    /// - `dx`: in/out X component of a distance vector
    /// - `dy`: in/out Y component of a distance vector
    pub fn transformDistance(self: *const Matrix, dx: *f64, dy: *f64) void {
        c.pango_matrix_transform_distance(self, dx, dy);
    }

    /// First transforms `rect` using `self`, then calculates the bounding box
    /// of the transformed rectangle.
    ///
    /// This function is useful for example when you want to draw a rotated
    /// `pango.Layout` to an image buffer, and want to know how large the image
    /// should be and how much you should shift the layout when rendering.
    ///
    /// If you have a rectangle in device units (pixels), use
    /// `pango.Matrix.transformPixelRectangle()`.
    ///
    /// If you have the rectangle in Pango units and want to convert to
    /// transformed pixel bounding box, it is more accurate to transform it
    /// first (using this function) and pass the result to `pango_extents_to_pixels()`,
    /// first argument, for an inclusive rounded rectangle. However, there are
    /// valid reasons that you may want to convert to pixels first and then
    /// transform, for example when the transformed coordinates may overflow in
    /// Pango units (large matrix translation for example).
    ///
    /// **Parameters**
    /// - `rect`: in/out bounding box in Pango units
    pub fn transformRectangle(self: *const Matrix, rect: *pango.Rectangle) void {
        // TODO: fix desc
        c.pango_matrix_transform_rectangle(self, rect);
    }

    /// First transforms the `rect` using `self`, then calculates the bounding
    /// box of the transformed rectangle.
    ///
    /// This function is useful for example when you want to draw a rotated
    /// `pango.Layout` to an image buffer, and want to know how large the image
    /// should be and how much you should shift the layout when rendering.
    ///
    /// For better accuracy, you should use `pango.Matrix.transformRectangle()`
    /// on original rectangle in Pango units and convert to pixels afterward
    /// `using pango_extents_to_pixels()`‘s first argument.
    ///
    /// **Parameters**
    /// - `rect`: in/out bounding box in device units
    pub fn transformPixelRectangle(self: *const Matrix, rect: *pango.Rectangle) void {
        // TODO: fix desc
        c.pango_matrix_transform_pixel_rectangle(self, rect);
    }

    /// Returns the scale factor of a matrix on the height of the font.
    ///
    /// That is, the scale factor in the direction perpendicular to the vector
    /// that the X coordinate is mapped to. If the scale in the X coordinate is
    /// needed as well, use `pango.Matrix.getFontScaleFactors()`.
    ///
    /// **Returns**
    ///
    /// the scale factor of `self` matrix on the height of the font.
    pub fn getFontScaleFactor(self: *const Matrix) f64 {
        return c.pango_matrix_get_font_scale_factor(self);
    }

    /// Calculates the scale factor of a matrix on the width and height of the
    /// font.
    ///
    /// That is, `xscale` is the scale factor in the direction of the X
    /// coordinate, and `yscale` is the scale factor in the direction
    /// perpendicular to the vector that the X coordinate is mapped to.
    ///
    /// Note that output numbers will always be non-negative.
    ///
    /// **Parameters**
    /// - `xscale`: output scale factor in the x direction
    /// - `yscale`: output scale factor in the y direction
    pub fn getFontScaleFactors(self: *const Matrix, xscale: ?*f64, yscale: ?*f64) void {
        c.pango_matrix_get_font_scale_factors(self, xscale, yscale);
    }

    /// Gets the slant ratio of a matrix.
    ///
    /// For a simple shear matrix in the form:
    /// ```code
    /// 1 λ
    /// 0 1
    /// ```
    /// this is simply λ.
    ///
    /// **Returns**
    ///
    /// the slant ratio of `self` matrix.
    pub fn getSlantRatio(self: *const Matrix) f64 {
        return c.pango_matrix_get_slant_ratio(self);
    }
};
