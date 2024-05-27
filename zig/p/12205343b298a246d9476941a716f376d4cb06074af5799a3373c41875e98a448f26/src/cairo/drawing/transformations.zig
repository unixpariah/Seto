//! Transformations — Manipulating the current transformation matrix
//!
//! The current transformation matrix, *ctm*, is a two-dimensional affine
//! transformation that maps all coordinates and other drawing instruments from
//! the *user space* into the surface's canonical coordinate system, also known
//! as the *device space*.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html)

const cairo = @import("../../cairo.zig");
const c = cairo.c;

const Context = cairo.Context;
const Matrix = cairo.Matrix;

/// Modifies the current transformation matrix (CTM) by translating the
/// user-space origin by `(tx, ty)`. This offset is interpreted as a
/// user-space coordinate according to the CTM in place before the new call
/// to `cr.translate()`. In other words, the translation of the user-space
/// origin takes place after any existing transformation.
///
/// **Parameters**
/// - `tx`: amount to translate in the X direction
/// - `ty`: amount to translate in the Y direction
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-translate)
pub fn translate(self: *Context, tx: f64, ty: f64) void {
    c.cairo_translate(self, tx, ty);
}

/// Modifies the current transformation matrix (CTM) by scaling the X and Y
/// user-space axes by `sx` and `sy` respectively. The scaling of the axes
/// takes place after any existing transformation of user space.
///
/// **Parameters**
/// - `sx`: scale factor for the X dimension
/// - `sy`: scale factor for the Y dimension
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-scale)
pub fn scale(self: *Context, sx: f64, sy: f64) void {
    c.cairo_scale(self, sx, sy);
}

/// Modifies the current transformation matrix (CTM) by rotating the
/// user-space axes by `angle` radians. The rotation of the axes takes
/// places after any existing transformation of user space. The rotation
/// direction for positive angles is from the positive X axis toward the
/// positive Y axis.
///
/// **Parameters**
/// - `angle`: angle (in radians) by which the user-space axes will be
/// rotated
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-rotate)
pub fn rotate(self: *Context, angle: f64) void {
    c.cairo_rotate(self, angle);
}

/// Modifies the current transformation `matrix` (CTM) by applying matrix
/// as an additional transformation. The new transformation of user space
/// takes place after any existing transformation.
///
/// **Parameters**
/// - `matrix`: a transformation to be applied to the user-space axes
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-transform)
pub fn transform(self: *Context, matrix: *const Matrix) void {
    c.cairo_transform(self, matrix);
}

/// Modifies the current transformation matrix (CTM) by setting it equal to
/// `matrix`.
///
/// **Parameters**
/// - `matrix`: a transformation matrix from user space to device space
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-set-matrix)
pub fn setMatrix(self: *Context, matrix: *const Matrix) void {
    c.cairo_set_matrix(self, matrix);
}

/// Stores the current transformation matrix (CTM) into `matrix`.
///
/// **Parameters**
/// - `matrix`: return value for the matrix
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-get-matrix)
pub fn getMatrix(self: *Context, matrix: *Matrix) void {
    c.cairo_get_matrix(self, matrix);
}

/// Resets the current transformation matrix (CTM) by setting it equal to
/// the identity matrix. That is, the user-space and device-space axes will
/// be aligned and one user-space unit will transform to one device-space
/// unit.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-identity-matrix)
pub fn identityMatrix(self: *Context) void {
    c.cairo_identity_matrix(self);
}

/// Transform a coordinate from user space to device space by multiplying
/// the given point by the current transformation matrix (CTM).
///
/// **Parameters**
/// - `x`: X value of coordinate (in/out parameter)
/// - `y`: Y value of coordinate (in/out parameter)
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-user-to-device)
pub fn userToDevice(self: *Context, x: *f64, y: *f64) void {
    c.cairo_user_to_device(self, x, y);
}

/// Transform a distance vector from user space to device space. This
/// function is similar to `cr.userToDevice()` except that the translation
/// components of the CTM will be ignored when transforming `(dx, dy)`.
///
/// **Parameters**
/// - `x`: X component of a distance vector (in/out parameter)
/// - `y`: Y component of a distance vector (in/out parameter)
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-user-to-device-distance)
pub fn userToDeviceDistance(self: *Context, dx: *f64, dy: *f64) void {
    c.cairo_user_to_device_distance(self, dx, dy);
}

/// Transform a coordinate from device space to user space by multiplying
/// the given point by the inverse of the current transformation matrix
/// (CTM).
///
/// **Parameters**
/// - `x`: X value of coordinate (in/out parameter)
/// - `y`: Y value of coordinate (in/out parameter)
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-device-to-user)
pub fn deviceToUser(self: *Context, x: *f64, y: *f64) void {
    c.cairo_device_to_user(self, x, y);
}

/// Transform a distance vector from device space to user space. This
/// function is similar to `cr.userToDevice()` except that the translation
/// components of the inverse CTM will be ignored when transforming
/// `(dx, dy)`.
///
/// **Parameters**
/// - `x`: X component of a distance vector (in/out parameter)
/// - `y`: Y component of a distance vector (in/out parameter)
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Transformations.html#cairo-device-to-user-distance)
pub fn deviceToUserDistance(self: *Context, dx: *f64, dy: *f64) void {
    c.cairo_device_to_user_distance(self, dx, dy);
}
