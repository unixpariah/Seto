const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const wayland = @import("wayland");
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;

const Seto = @import("main.zig").Seto;

pub const OutputInfo = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    height: i32 = 0,
    width: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    wl_output: *wl.Output,

    const Self = @This();

    fn destroy(self: *Self, alloc: mem.Allocator) void {
        self.wl_output.destroy();
        alloc.free(self.name.?);
        alloc.free(self.description.?);
    }
};

pub const Surface = struct {
    layer_surface: *zwlr.LayerSurfaceV1,
    surface: *wl.Surface,
    alloc: mem.Allocator,
    output_info: OutputInfo,
    xdg_output: *zxdg.OutputV1,
    mmap: ?[]align(mem.page_size) u8 = null,
    fd: std.posix.fd_t,
    pool: *wl.ShmPool,

    const Self = @This();

    pub fn new(surface: *wl.Surface, layer_surface: *zwlr.LayerSurfaceV1, alloc: mem.Allocator, xdg_output: *zxdg.OutputV1, output_info: OutputInfo, shm: *wl.Shm) Self {
        const fd = posix.memfd_create("seto", 0) catch |err| @panic(@errorName(err));
        const pool = shm.createPool(fd, 1) catch |err| @panic(@errorName(err));
        return .{ .fd = fd, .surface = surface, .layer_surface = layer_surface, .alloc = alloc, .output_info = output_info, .xdg_output = xdg_output, .pool = pool };
    }

    pub fn cmp(self: Self, a: Self, b: Self) bool {
        _ = self;
        if (a.output_info.x != b.output_info.x)
            return a.output_info.x < b.output_info.x
        else
            return a.output_info.y < b.output_info.y;
    }

    pub fn draw(self: *Self, data: [*]u8) !void {
        const width = self.output_info.width;
        const height = self.output_info.height;
        const stride = width * 4;
        const size: usize = @intCast(stride * height);

        if (self.mmap == null) {
            try posix.ftruncate(self.fd, @intCast(size));
            self.pool.resize(@intCast(size));
            self.mmap = try posix.mmap(null, size, posix.PROT.READ | posix.PROT.WRITE, posix.MAP{ .TYPE = .SHARED }, self.fd, 0);
        }
        @memcpy(self.mmap.?, data);

        const buffer = try self.pool.createBuffer(0, width, height, stride, wl.Shm.Format.argb8888);
        defer buffer.destroy();

        self.surface.damage(0, 0, width, height);
        self.surface.attach(buffer, 0, 0);
        self.surface.commit();
    }

    pub fn isConfigured(self: *const Self) bool {
        return self.output_info.width > 0 and self.output_info.height > 0;
    }

    pub fn destroy(self: *Self) void {
        self.layer_surface.destroy();
        self.surface.destroy();
        self.output_info.destroy(self.alloc);
        self.xdg_output.destroy();
        if (self.mmap) |mmap| {
            posix.munmap(mmap);
        }
        self.pool.destroy();
        std.posix.close(self.fd);
    }
};

pub fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
        .configure => |configure| {
            for (seto.outputs.items) |*surface| {
                if (surface.layer_surface == lsurf) {
                    surface.layer_surface.setSize(configure.width, configure.height);
                    surface.layer_surface.ackConfigure(configure.serial);
                }
            }
        },
        .closed => {},
    }
}

pub fn xdgOutputListener(
    output: *zxdg.OutputV1,
    event: zxdg.OutputV1.Event,
    seto: *Seto,
) void {
    for (seto.outputs.items) |*surface| {
        if (surface.xdg_output == output) {
            switch (event) {
                .name => |e| {
                    surface.output_info.name = seto.alloc.dupe(u8, mem.span(e.name)) catch return;
                },
                .description => |e| {
                    surface.output_info.description = seto.alloc.dupe(u8, mem.span(e.description)) catch return;
                },
                .logical_position => |pos| {
                    surface.output_info.x = pos.x;
                    surface.output_info.y = pos.y;
                },
                .logical_size => |size| {
                    surface.output_info.height = size.height;
                    surface.output_info.width = size.width;
                },
                .done => {},
            }
        }
    }

    seto.updateDimensions();
    seto.sortOutputs();
}
