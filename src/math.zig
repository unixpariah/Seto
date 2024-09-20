const std = @import("std");

pub const Mat4 = [4][4]f32;

pub fn mul(m0: Mat4, m1: Mat4) Mat4 {
    var result: Mat4 = undefined;
    comptime var row: u32 = 0;
    inline while (row < 4) : (row += 1) {
        var vx = @shuffle(f32, m0[row], undefined, [4]i32{ 0, 0, 0, 0 });
        var vy = @shuffle(f32, m0[row], undefined, [4]i32{ 1, 1, 1, 1 });
        var vz = @shuffle(f32, m0[row], undefined, [4]i32{ 2, 2, 2, 2 });
        var vw = @shuffle(f32, m0[row], undefined, [4]i32{ 3, 3, 3, 3 });
        vx = vx * m1[0];
        vy = vy * m1[1];
        vz = vz * m1[2];
        vw = vw * m1[3];
        vx = vx + vz;
        vy = vy + vw;
        vx = vx + vy;
        result[row] = vx;
    }
    return result;
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
        .{ -(right + left) / (right - left), -(top + bottom) / (top - bottom), (1 + 0) / -1, 1.0 },
    };
}

pub inline fn translate(x: f32, y: f32, z: f32) Mat4 {
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
