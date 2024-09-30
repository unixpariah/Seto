const std = @import("std");

pub const Mat4 = [4][4]f32;
pub const Vec4 = [4]f32;

pub fn transform(font_size: f32, m1: Vec4) Mat4 {
    var result: Mat4 = undefined;
    var vx = @shuffle(f32, [4]i32{ 0, 0, 0, 1 }, undefined, [4]i32{ 0, 0, 0, 0 });
    var vy = @shuffle(f32, [4]i32{ 0, 0, 0, 1 }, undefined, [4]i32{ 1, 1, 1, 1 });
    var vw = @shuffle(f32, [4]i32{ 0, 0, 0, 1 }, undefined, [4]i32{ 3, 3, 3, 3 });
    vx = vx * [4]f32{ 1, 0, 0, 0 };
    vy = vy * [4]f32{ 0, 1, 0, 0 };
    vw = vw * m1;
    vy = vy + vw;
    vx = vx + vy;
    result[3] = vx;

    result[0] = .{ font_size, 0, 0, 0 };
    result[1] = .{ 0, font_size, 0, 0 };
    result[2] = .{ 0, 0, 0, 0 };

    return result;
}

pub fn translate(x: f32, y: f32) Vec4 {
    return .{ x, y, 0, 1 };
}

pub fn mat4() Mat4 {
    return .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
}

pub fn orthographicProjection(left: f32, right: f32, top: f32, bottom: f32) Mat4 {
    return .{
        .{ 2 / (right - left), 0.0, 0.0, 0.0 },
        .{ 0.0, 2 / (top - bottom), 0.0, 0.0 },
        .{ 0.0, 0.0, 2, 0.0 },
        .{ -(right + left) / (right - left), -(top + bottom) / (top - bottom), -1, 1.0 },
    };
}
