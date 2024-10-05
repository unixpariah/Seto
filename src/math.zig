const std = @import("std");

pub const Mat4 = [4][4]f32;
pub const Mat3 = [3][3]f32;
const Vector = @Vector(2, f32);

pub fn transform(font_size: f32, x: f32, y: f32) Mat4 {
    return .{
        .{ font_size, 0, 0, 0 },
        .{ 0, font_size, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ x, y, 0, 1 },
    };
}

pub fn transform2D(font_size: f32, x: f32, y: f32) Mat3 {
    return .{
        .{ font_size, 0, x },
        .{ 0, font_size, y },
        .{ 0, 0, 1 },
    };
}

pub fn mat3() Mat3 {
    return .{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    };
}

pub fn mat4() Mat4 {
    return .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    };
}

pub fn orthographicProjection2D(left: f32, right: f32, top: f32, bottom: f32) Mat3 {
    return .{
        .{ 2 / (right - left), 0.0, 0.0 },
        .{ 0.0, 2 / (top - bottom), 0.0 },
        .{ -(right + left) / (right - left), -(top + bottom) / (top - bottom), 1.0 },
    };
}

pub fn orthographicProjection(left: f32, right: f32, top: f32, bottom: f32) Mat4 {
    return .{
        .{ 2 / (right - left), 0.0, 0.0, 0.0 },
        .{ 0.0, 2 / (top - bottom), 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ -(right + left) / (right - left), -(top + bottom) / (top - bottom), 0, 1.0 },
    };
}
