const std = @import("std");
const os = std.os;
const mem = std.mem;

const wayland = @import("wayland");
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;

const Seto = @import("main.zig").Seto;

const cairo = @import("cairo");

pub const OutputInfo = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    height: i32 = 0,
    width: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    wl: *wl.Output,
    alloc: mem.Allocator,

    pub fn deinit(self: OutputInfo) void {
        if (self.name) |name| self.allocator.free(name);
        if (self.description) |description| self.allocator.free(description);
    }
};

pub const Surface = struct {
    layer_surface: *zwlr.LayerSurfaceV1,
    surface: *wl.Surface,
    dimensions: [2]c_int = undefined,
    alloc: mem.Allocator,
    output_info: *OutputInfo,

    pub fn new(surface: *wl.Surface, layer_surface: *zwlr.LayerSurfaceV1, alloc: mem.Allocator, output_info: *OutputInfo) Surface {
        return Surface{ .surface = surface, .layer_surface = layer_surface, .alloc = alloc, .output_info = output_info };
    }

    fn create_surface(self: *Surface) !*cairo.ImageSurface {
        const width = self.dimensions[0];
        const height = self.dimensions[1];

        const cairo_surface = try cairo.ImageSurface.create(.argb32, @intCast(self.dimensions[0]), @intCast(self.dimensions[1]));

        const context = try cairo.Context.create(cairo_surface.asSurface());
        defer context.destroy();

        context.setSourceRgb(0.5, 0.5, 0.5);
        context.paintWithAlpha(0.5);

        context.setSourceRgb(1, 1, 1);

        const gridSize = 50;
        var i: usize = 0;
        while (i < width) : (i += gridSize) {
            context.moveTo(@floatFromInt(i), 0);
            context.lineTo(@floatFromInt(i), @floatFromInt(height));
        }

        i = 0;
        while (i < height) : (i += gridSize) {
            context.moveTo(0, @floatFromInt(i));
            context.lineTo(@floatFromInt(width), @floatFromInt(i));
        }
        context.stroke();

        return cairo_surface;
    }

    pub fn draw(self: *Surface, pool: *wl.ShmPool, fd: i32) !void {
        var list = std.ArrayList(u8).init(self.alloc);
        defer list.deinit();

        const width = self.dimensions[0];
        const height = self.dimensions[1];
        const stride = width * 4;
        const size: usize = @intCast(stride * height);
        try list.resize(size);

        const cairo_surface = try self.create_surface();
        defer cairo_surface.destroy();

        @memcpy(list.items, try cairo_surface.getData());

        const data = try os.mmap(null, size, os.PROT.READ | os.PROT.WRITE, os.MAP.SHARED, fd, 0);
        defer os.munmap(data);
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

pub fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
        .configure => |configure| {
            for (seto.outputs.items) |*surface| {
                if (surface.layer_surface == lsurf) {
                    surface.dimensions = .{ @intCast(configure.width), @intCast(configure.height) };
                    surface.layer_surface.setSize(configure.width, configure.height);
                    surface.layer_surface.ackConfigure(configure.serial);
                }
            }
        },
        .closed => {},
    }
}

pub fn xdgOutputListener(
    _: *zxdg.OutputV1,
    ev: zxdg.OutputV1.Event,
    info: *OutputInfo,
) void {
    switch (ev) {
        .name => |e| {
            info.name = std.mem.span(e.name);
        },

        .description => |e| {
            info.description = std.mem.span(e.description);
        },

        .logical_position => |pos| {
            info.x = pos.x;
            info.y = pos.y;
        },

        .logical_size => |size| {
            info.height = size.height;
            info.width = size.width;
        },

        else => {},
    }
}
