const std = @import("std");

pub const Mat4 = [4][4]f32;

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
        .{ -(right + left) / (right - left), -(top + bottom) / (top - bottom), (1 + 0) / -1, 1.0 },
    };
}

pub fn translate(x: f32, y: f32, z: f32) Mat4 {
    return .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ x, y, z, 1 },
    };
}

pub fn scale(x: f32, y: f32, z: f32) Mat4 {
    return .{
        .{ x, 0, 0, 0 },
        .{ 0, y, 0, 0 },
        .{ 0, 0, z, 0 },
        .{ 0, 0, 0, 1 },
    };
}

pub fn mul(m0: Mat4, m1: Mat4) Mat4 {
    var result: Mat4 = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = 0;
            for (0..4) |k| {
                result[i][j] += m0[i][k] * m1[k][j];
            }
        }
    }

    return result;
}
