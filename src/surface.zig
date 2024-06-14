const std = @import("std");
const mem = std.mem;
const posix = std.posix;

const wayland = @import("wayland");
const zwlr = wayland.client.zwlr;
const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;
const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("GLES2/gl2.h");
    @cInclude("EGL/egl.h");
});

const Seto = @import("main.zig").Seto;
const Tree = @import("tree.zig").Tree;

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
    buffer: ?*wl.Buffer = null,
    egl_display: ?c.EGLDisplay = null,
    egl_surface: ?c.EGLSurface = null,

    const Self = @This();

    pub fn new(
        surface: *wl.Surface,
        layer_surface: *zwlr.LayerSurfaceV1,
        alloc: mem.Allocator,
        xdg_output: *zxdg.OutputV1,
        output_info: OutputInfo,
    ) Self {
        return .{
            .surface = surface,
            .layer_surface = layer_surface,
            .alloc = alloc,
            .output_info = output_info,
            .xdg_output = xdg_output,
        };
    }

    pub fn posInSurface(self: Self, coordinates: [2]i32) bool {
        const info = self.output_info;
        return coordinates[0] < info.x + info.width and coordinates[0] >= info.x and coordinates[1] < info.y + info.height and coordinates[1] >= info.y;
    }

    pub fn cmp(_: Self, a: Self, b: Self) bool {
        if (a.output_info.x != b.output_info.x)
            return a.output_info.x < b.output_info.x
        else
            return a.output_info.y < b.output_info.y;
    }

    pub fn draw(self: *Self) !void {
        c.glClearColor(1, 1, 0, 1);
        if (c.eglSwapBuffers(self.egl_display.?, self.egl_surface.?) != c.EGL_TRUE) {
            std.debug.print("EGLError", .{});
            std.process.exit(1);
        }
    }

    pub fn isConfigured(self: *const Self) bool {
        return self.output_info.width > 0 and self.output_info.height > 0;
    }

    pub fn destroy(self: *Self) void {
        self.layer_surface.destroy();
        self.surface.destroy();
        self.output_info.destroy(self.alloc);
        self.xdg_output.destroy();
        self.buffer.?.destroy();
        posix.munmap(self.mmap.?);
    }
};

pub const SurfaceIterator = struct {
    position: [2]i32 = .{ 0, 0 },
    outputs: []Surface,
    index: u8 = 0,

    const Self = @This();

    pub fn new(outputs: []Surface) Self {
        return Self{ .outputs = outputs };
    }

    pub fn next(self: *Self) ?std.meta.Tuple(&.{ Surface, [2]i32 }) {
        if (self.index >= self.outputs.len) return null;
        const output = self.outputs[self.index];
        const info = output.output_info;
        if (!output.isConfigured()) return self.next();

        if (self.index > 0) {
            if (info.x <= self.outputs[self.index - 1].output_info.x) self.position = .{ 0, self.outputs[self.index - 1].output_info.height };
        }

        defer self.index += 1;
        defer self.position[0] += info.width;

        return .{ output, self.position };
    }
};

pub fn frameListener(callback: *wl.Callback, event: wl.Callback.Event, surface: *Surface) void {
    defer callback.destroy();
    if (event == .done) surface.draw() catch return;
}

pub fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, seto: *Seto) void {
    switch (event) {
        .configure => |configure| {
            for (seto.outputs.items) |*surface| {
                if (surface.layer_surface == lsurf) {
                    surface.layer_surface.setSize(configure.width, configure.height);
                    surface.layer_surface.ackConfigure(configure.serial);

                    const size = configure.width * configure.height * 4;

                    const fd = posix.memfd_create("seto", 0) catch |err| @panic(@errorName(err));
                    posix.ftruncate(fd, size) catch @panic("OOM");

                    const pool = seto.shm.?.createPool(fd, @intCast(size)) catch |err| @panic(@errorName(err));

                    defer std.posix.close(fd);
                    defer pool.destroy();

                    if (surface.mmap) |mmap| posix.munmap(mmap);
                    if (surface.buffer) |buffer| buffer.destroy();

                    surface.mmap = posix.mmap(null, size, posix.PROT.READ | posix.PROT.WRITE, posix.MAP{ .TYPE = .SHARED }, fd, 0) catch @panic("OOM");

                    surface.buffer = pool.createBuffer(0, @intCast(configure.width), @intCast(configure.height), @intCast(configure.width * 4), wl.Shm.Format.argb8888) catch unreachable;

                    const region = seto.compositor.?.createRegion() catch unreachable;
                    region.add(0, 0, @intCast(configure.width), @intCast(configure.height));
                    surface.surface.setOpaqueRegion(region);
                    surface.egl_surface = seto.egl.createSurface(surface.surface, @intCast(configure.width), @intCast(configure.height));
                    surface.egl_display = seto.egl.display;

                    if (!surface.isConfigured()) surface.draw() catch return;
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
                    surface.output_info.name = seto.alloc.dupe(u8, mem.span(e.name)) catch @panic("OOM");
                },
                .description => |e| {
                    surface.output_info.description = seto.alloc.dupe(u8, mem.span(e.description)) catch @panic("OOM");
                },
                .logical_position => |pos| {
                    surface.output_info.x = pos.x;
                    surface.output_info.y = pos.y;
                },
                .logical_size => |size| {
                    surface.output_info.height = size.height;
                    surface.output_info.width = size.width;

                    seto.updateDimensions();
                    seto.sortOutputs();

                    if (seto.tree) |tree| tree.arena.deinit();
                    seto.tree = Tree.new(
                        seto.config.keys.search,
                        seto.alloc,
                        seto.total_dimensions,
                        seto.config.grid,
                        seto.outputs.items,
                    );
                },
                .done => {},
            }
        }
    }
}
