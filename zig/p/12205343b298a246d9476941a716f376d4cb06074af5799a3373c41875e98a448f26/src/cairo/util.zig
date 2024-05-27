const std = @import("std");
const testing = std.testing;

const cairo = @import("../cairo.zig");
const c = cairo.c;
const Status = cairo.Status;

/// A Transformation matrix.
///
/// `cairo.Matrix` is used to convert between different coordinate spaces. It
/// holds an affine transformation, such as a scale, rotation, shear, or a
/// combination of those. The transformation of a point (x, y) is given by:
/// ```code
/// x_new = xx * x + xy * y + x0;
/// y_new = yx * x + yy * y + y0;
/// ```
///
/// The current transformation matrix of a `cairo.Context`, represented as a
/// `cairo.Matrix`, defines the transformation from user-space coordinates to
/// device-space coordinates. See also:
/// - `cairo.Context.getMatrix()`
/// - `cairo.Context.setMatrix()`
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-t)
pub const Matrix = extern struct {
    /// xx component of the affine transformation
    xx: f64,
    /// yx component of the affine transformation
    yx: f64,
    /// xy component of the affine transformation
    xy: f64,
    /// yy component of the affine transformation
    yy: f64,
    /// X translation component of the affine transformation
    x0: f64,
    /// Y translation component of the affine transformation
    y0: f64,

    /// Creates a matrix to be the affine transformation given by `xx`, `yx`,
    /// `xy`, `yy`, `x0`, `y0`. The transformation is given by:
    /// ```code
    /// x_new = xx * x + xy * y + x0;
    /// y_new = yx * x + yy * y + y0;
    /// ```
    ///
    /// **Parameters**
    /// - `xx`: xx component of the affine transformation
    /// - `yx`: yx component of the affine transformation
    /// - `xy`: xy component of the affine transformation
    /// - `yy`: yy component of the affine transformation
    /// - `x0`: X translation component of the affine transformation
    /// - `y0`: Y translation component of the affine transformation
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init)
    pub fn init(xx: f64, yx: f64, xy: f64, yy: f64, x0: f64, y0: f64) Matrix {
        var m: Matrix = undefined;
        c.cairo_matrix_init(&m, xx, yx, xy, yy, x0, y0);
        return m;
    }

    /// Creates a `cairo.Matrix` initialized to be an identity transformation.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-identity)
    pub fn identity() Matrix {
        var m: Matrix = undefined;
        c.cairo_matrix_init_identity(&m);
        return m;
    }

    /// Creates a `cairo.Matrix` initialized to a transformation that
    /// translates by `tx` and `ty` in the X and Y dimensions, respectively.
    ///
    /// **Parameters**
    /// - `tx`: amount to translate in the X direction
    /// - `ty`: amount to translate in the Y direction
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-translate)
    pub fn translation(tx: f64, ty: f64) Matrix {
        var m: Matrix = undefined;
        c.cairo_matrix_init_translate(&m, tx, ty);
        return m;
    }

    /// Creates a `cairo.Matrix` inititalized to a transformation that scales
    /// by `sx` and `sy` in the X and Y dimensions, respectively.
    ///
    /// **Parameters**
    /// - `sx`: scale factor in the X direction
    /// - `sy`: scale factor in the Y direction
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-scale)
    pub fn scaling(sx: f64, sy: f64) Matrix {
        var m: Matrix = undefined;
        c.cairo_matrix_init_scale(&m, sx, sy);
        return m;
    }

    /// Creates a `cairo.Matrix` initialized to a transformation that rotates
    /// by `radians`.
    ///
    /// **Parameters**
    /// - `radians`: angle of rotation, in radians. The direction of rotation
    /// is defined such that positive angles rotate in the direction from the
    /// positive X axis toward the positive Y axis. With the default axis
    /// orientation of cairo, positive angles rotate in a clockwise direction.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-init-rotate)
    pub fn rotation(radians: f64) Matrix {
        var m: Matrix = undefined;
        c.cairo_matrix_init_rotate(&m, radians);
        return m;
    }

    /// Applies a translation by `tx`, `ty` to the transformation in `matrix`.
    /// The effect of the new transformation is to first translate the
    /// coordinates by `tx` and `ty` , then apply the original transformation
    /// to the coordinates.
    ///
    /// **Parameters**
    /// - `tx`: amount to translate in the X direction
    /// - `ty`: amount to translate in the Y direction
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-translate)
    pub fn translate(self: *Matrix, tx: f64, ty: f64) void {
        c.cairo_matrix_translate(self, tx, ty);
    }

    /// Applies scaling by `sx`, `sy` to the transformation in `matrix`. The
    /// effect of the new transformation is to first scale the coordinates by
    /// `sx` and `sy`, then apply the original transformation to the
    /// coordinates.
    ///
    /// **Parameters**
    /// - `sx`: scale factor in the X direction
    /// - `sy`: scale factor in the Y direction
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-scale)
    pub fn scale(self: *Matrix, sx: f64, sy: f64) void {
        c.cairo_matrix_scale(self, sx, sy);
    }

    /// Applies rotation by `radians` to the transformation in `matrix`. The
    /// effect of the new transformation is to first rotate the coordinates by
    /// `radians`, then apply the original transformation to the coordinates.
    ///
    /// **Parameters**
    /// - `radians`: angle of rotation, in radians. The direction of rotation
    /// is defined such that positive angles rotate in the direction from the
    /// positive X axis toward the positive Y axis. With the default axis
    /// orientation of cairo, positive angles rotate in a clockwise direction.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-rotate)
    pub fn rotate(self: *Matrix, radians: f64) void {
        c.cairo_matrix_rotate(self, radians);
    }

    /// Changes `matrix` to be the inverse of its original value. Not all
    /// transformation matrices have inverses; if the matrix collapses points
    /// together (it is *degenerate*), then it has no inverse and this function
    /// will fail.
    ///
    /// If `matrix` has an inverse, modifies matrix to be the inverse matrix
    /// and returns `.Success`. Otherwise, returns `.InvalidMatrix`.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-invert)
    pub fn invert(self: *Matrix) Status {
        return c.cairo_matrix_invert(self);
    }

    /// Multiplies the affine transformations in `a` and `b` together and
    /// stores the result in `self`. The effect of the resulting
    /// transformation is to first apply the transformation in `a` to the
    /// coordinates and then apply the transformation in `b` to the
    /// coordinates.
    ///
    /// It is allowable for `result` to be identical to either `a` or `b`.
    ///
    /// **Parameters**
    /// - `a`: a `cairo.Matrix`
    /// - `b`: a `cairo.Matrix`
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-multiply)
    pub fn multiply(self: *Matrix, a: *const Matrix, b: *const Matrix) void {
        c.cairo_matrix_multiply(self, a, b);
    }

    /// Transforms the distance vector (`dx`, `dy`) by `self` matrix. This is
    /// similar to `matrix.transformPoint()` except that the translation
    /// components of the transformation are ignored. The calculation of the
    /// returned vector is as follows:
    /// ```code
    /// dx2 = dx1 * a + dy1 * c;
    /// dy2 = dx1 * b + dy1 * d;
    /// ```
    /// Affine transformations are position invariant, so the same vector
    /// always transforms to the same vector. If `(x1, y1)` transforms to
    /// `(x2, y2)` then `(x1 + dx1, y1 + dy1)` will transform to
    /// `(x1 + dx2, y1 + dy2)` for all values of `x1` and `x2`.
    ///
    /// **Parameters**
    /// - `dx`: X component of a distance vector. An in/out parameter
    /// - `dy`: Y component of a distance vector. An in/out parameter
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-transform-distance)
    pub fn transformDistance(self: *const Matrix, dx: *f64, dy: *f64) void {
        c.cairo_matrix_transform_distance(self, dx, dy);
    }

    /// Transforms the point (`x`, `y`) by `self` matrix.
    ///
    /// **Parameters**
    /// - `x`: X position. An in/out parameter
    /// - `y`: Y position. An in/out parameter
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html#cairo-matrix-transform-point)
    pub fn transformPoint(self: *const Matrix, x: *f64, y: *f64) void {
        c.cairo_matrix_transform_point(self, x, y);
    }
};

/// `cairo.UserDataKey` is used for attaching user data to cairo data
/// structures. The actual contents of the struct is never used, and there is
/// no need to initialize the object; only the unique address of a
/// `cairo.UserDataKey` object is used. Typically, you would just use the
/// address of a static `cairo.UserDataKey` object.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Types.html#cairo-user-data-key-t)
pub const UserDataKey = extern struct {
    /// not used; ignore
    unused: c_int,
};

/// A data structure for holding a rectangle with integer coordinates.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-Types.html#cairo-rectangle-int-t)
pub const RectangleInt = extern struct {
    /// X coordinate of the left side of the rectangle
    x: c_int,
    /// Y coordinate of the the top side of the rectangle
    y: c_int,
    /// width of the rectangle
    width: c_int,
    /// height of the rectangle
    height: c_int,

    /// Init `cairo.RectangleInt` from [4]c_int array. Values are
    /// `.{x, y, width, height}`
    pub fn init(arr: [4]c_int) RectangleInt {
        return @bitCast(arr);
    }
};

// examine later
fn FromToInt(comptime Self: type) type {
    return struct {
        pub const TagType = @typeInfo(Self).Enum.tag_type;

        pub inline fn fromInt(int: TagType) Self {
            return @enumFromInt(int);
        }

        pub inline fn toInt(self: Self) TagType {
            return @intFromEnum(self);
        }
    };
}

pub const Point = extern struct {
    x: f64,
    y: f64,
};

/// A rectangle structure useful for calculating extents
pub const ExtentsRectangle = struct {
    /// left
    x1: f64,
    /// top
    y1: f64,
    /// right
    x2: f64,
    /// bottom
    y2: f64,
};

/// `cairo.ReadFn` is the type of function which is called when a backend needs
/// to read data from an input stream. It is passed the closure which was
/// specified by the user at the time the read function was registered, the
/// buffer to read the data into and the length of the data in bytes. The read
/// function should return `cairo.Status.Success` if all the data was
/// successfully read, `cairo.Status.ReadError` otherwise.
///
/// **Parameters**
/// - `closure`: the input closure
/// - `data`: the buffer into which to read the data
/// - `length`: the amount of data to read
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PNG-Support.html#cairo-read-func-t)
pub const ReadFn = ?*const fn (closure: ?*anyopaque, data: [*c]u8, length: c_uint) callconv(.C) Status;

pub fn createReadFn(comptime readerT: type) ReadFn {
    // force add const qualifier to a ptr
    comptime var info = @typeInfo(readerT).Pointer;
    info.is_const = true;
    const T = @Type(.{ .Pointer = info });

    const S = struct {
        pub fn readFn(erased_stream: ?*const anyopaque, data: [*c]u8, len: c_uint) callconv(.C) Status {
            const casted_stream: T = @ptrCast(@alignCast(erased_stream));
            const read = casted_stream.readAll(data[0..len]) catch return .ReadError;
            return if (read == len) .Success else .ReadError;
        }
    };

    return &S.readFn;
}

test "ReadFn" {
    var buf = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    var read_buf: [buf.len]u8 = undefined;

    var stream = std.io.fixedBufferStream(&buf);
    var reader = stream.reader();

    const readFn = createReadFn(@TypeOf(&reader));
    const status = readFn.?(@ptrCast(&reader), &read_buf, read_buf.len);
    try testing.expect(status == .Success);
    try testing.expectEqualSlices(u8, buf[0..], read_buf[0..]);
}

/// `cairo.WriteFn` is the type of function which is called when a backend
/// needs to write data to an output stream. It is passed the closure which was
/// specified by the user at the time the write function was registered, the
/// data to write and the length of the data in bytes. The write function
/// should return `cairo.Status.Success` if all the data was successfully
/// written, `cairo.Status.WriteError` otherwise.
///
/// **Parameters**
/// - `closure`: the output closure
/// - `data`: the buffer containing the data to write
/// - `length`: the amount of data to write
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-PNG-Support.html#cairo-write-func-t)
pub const WriteFn = ?*const fn (closure: ?*anyopaque, data: [*c]const u8, length: c_uint) callconv(.C) Status;

pub fn createWriteFn(comptime writerT: type) WriteFn {
    // force add const qualifier to a ptr
    comptime var info = @typeInfo(writerT).Pointer;
    info.is_const = true;
    const T = @Type(.{ .Pointer = info });

    const S = struct {
        pub fn writeFn(erased_stream: ?*const anyopaque, data: [*c]const u8, len: c_uint) callconv(.C) Status {
            const casted_stream: T = @ptrCast(@alignCast(erased_stream));
            casted_stream.writeAll(data[0..len]) catch return .WriteError;
            return .Success;
        }
    };

    return &S.writeFn;
}

test "WriteFn" {
    var write_buf = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    var buf: [write_buf.len]u8 = undefined;

    var stream = std.io.fixedBufferStream(&buf);
    var writer = stream.writer();

    const writeFn = createWriteFn(@TypeOf(&writer));
    const status = writeFn.?(@ptrCast(&writer), &write_buf, write_buf.len);
    try testing.expect(status == .Success);
    try testing.expectEqualSlices(u8, write_buf[0..], buf[0..]);
}

/// `cairo.DestroyFn` is the type of function which is called when a data
/// element is destroyed. It is passed the pointer to the data element and
/// should free any memory and resources allocated for it.
pub const DestroyFn = ?*const fn (?*anyopaque) callconv(.C) void;
