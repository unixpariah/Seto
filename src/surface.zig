const std = @import("std");
const os = std.os;
const wayland = @import("wayland");

const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const mem = std.mem;

pub const Surface = struct {
    layer_surface: *zwlr.LayerSurfaceV1,
    surface: *wl.Surface,
    dimensions: [2]c_int,
    alloc: mem.Allocator,

    pub fn new(surface: *wl.Surface, layer_surface: *zwlr.LayerSurfaceV1, alloc: mem.Allocator) Surface {
        return Surface{ .surface = surface, .layer_surface = layer_surface, .alloc = alloc, .dimensions = undefined };
    }

    pub fn draw(self: *Surface, pool: *wl.ShmPool, fd: i32) !void {
        var list = std.ArrayList(u8).init(self.alloc);
        defer list.deinit();

        const width = self.dimensions[0];
        const height = self.dimensions[1];
        const stride = width * 4;
        const size: usize = @intCast(stride * height);

        try list.resize(size);
        @memset(list.items, 50);

        const data = try os.mmap(null, size, os.PROT.READ | os.PROT.WRITE, os.MAP.SHARED, fd, 0);
        @memcpy(data, list.items);

        const buffer = try pool.createBuffer(0, width, height, stride, wl.Shm.Format.argb8888);
        defer buffer.destroy();

        self.surface.attach(buffer, 0, 0);
        self.surface.commit();
    }

    pub fn is_configured(self: *Surface) bool {
        return self.dimensions[0] > 0 and self.dimensions[1] > 0;
    }

    pub fn destroy(self: *Surface) void {
        self.surface.destroy();
        self.layer_surface.destroy();
    }
};
