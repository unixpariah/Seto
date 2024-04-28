const std = @import("std");
const os = std.os;
const wayland = @import("wayland");

const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const mem = std.mem;

pub const Surface = struct {
    layer_surface: *zwlr.LayerSurfaceV1,
    surface: *wl.Surface,
    size: [2]c_int,

    pub fn draw(self: *const Surface, pool: *wl.ShmPool, fd: i32) !void {
        var list = std.ArrayList(u8).init(std.heap.page_allocator);
        defer list.deinit();

        const width = self.size[0];
        const height = self.size[1];
        const stride = width * 4;
        const size: usize = @intCast(stride * height);

        try list.resize(size);
        @memset(list.items, 50);

        const data = try os.mmap(null, size, os.PROT.READ | os.PROT.WRITE, os.MAP.SHARED, fd, 0);
        @memcpy(data, list.items);

        const buffer = try pool.createBuffer(0, width, height, stride, wl.Shm.Format.argb8888);

        self.surface.attach(buffer, 0, 0);
        self.surface.commit();

        defer buffer.destroy();
    }
};
