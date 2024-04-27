const std = @import("std");
const mem = std.mem;
const os = std.os;

const wayland = @import("wayland");
const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;

const EventInterfaces = enum {
    wl_shm,
    wl_compositor,
    zwlr_layer_shell_v1,
    wl_output,
    zxdg_output_manager_v1,
};

const OutputInfo = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    height: i32 = 0,
    width: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    wl: *wl.Output,

    pub fn deinit(self: OutputInfo) void {
        var alloc = std.heap.page_allocator;
        if (self.name) |name| alloc.free(name);
        if (self.description) |description| self.alloc.free(description);
    }
};

const Context = struct {
    shm: ?*wl.Shm,
    compositor: ?*wl.Compositor,
    layer_shell: ?*zwlr.LayerShellV1,
    outputs: std.ArrayList(*wl.Output),
    output_info: ?*OutputInfo,
    fn new() Context {
        var alloc = std.heap.page_allocator;
        return Context{
            .shm = null,
            .compositor = null,
            .layer_shell = null,
            .output_info = null,
            .outputs = std.ArrayList(*wl.Output).init(alloc),
        };
    }

    fn create_buffer(self: *Context) !*wl.Buffer {
        var allocator = std.heap.page_allocator;
        var list = std.ArrayList(u8).init(allocator);
        defer list.deinit();

        const width = self.output_info.?.width;
        const height = self.output_info.?.height;
        const stride = width * 4;
        const size: usize = @intCast(stride * height);

        try list.resize(size);

        const fd = try os.memfd_create("sip", 0);
        try os.ftruncate(fd, size);
        const data = try os.mmap(null, size, os.PROT.READ | os.PROT.WRITE, os.MAP.SHARED, fd, 0);
        @memcpy(data, list.items);

        const shm = self.shm orelse return error.NoWlShm;
        const pool = try shm.createPool(fd, @intCast(size));
        defer pool.destroy();

        const buffer = try pool.createBuffer(0, width, height, stride, wl.Shm.Format.argb8888);

        return buffer;
    }
};

pub fn main() anyerror!void {
    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();

    var context = Context.new();

    registry.setListener(*Context, registryListener, &context);
    if (display.roundtrip() != .SUCCESS) return error.RoundtripFailed;

    const compositor = context.compositor orelse return error.NoWlCompositor;

    const surface = try compositor.createSurface();
    defer surface.destroy();

    const output = context.outputs.items[1];
    const layer_surface = try context.layer_shell.?.getLayerSurface(surface, output, .overlay, "sip");
    var winsize: [2]c_int = undefined;
    layer_surface.setListener(*[2]c_int, layerSurfaceListener, &winsize);
    layer_surface.setAnchor(.{
        .top = true,
        .right = true,
        .bottom = true,
        .left = true,
    });
    layer_surface.setExclusiveZone(-1);
    surface.commit();
    defer layer_surface.destroy();

    var running = true;

    while (running) {
        if (winsize[0] > 0) {
            context.output_info.?.width = winsize[0];
            context.output_info.?.height = winsize[1];
            winsize = undefined;
            const buffer = try context.create_buffer();
            defer buffer.destroy();

            surface.attach(buffer, 0, 0);
            surface.commit();
        }

        if (display.dispatch() != .SUCCESS) return error.DispatchFailed;
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, context: *Context) void {
    switch (event) {
        .global => |global| {
            const events = std.meta.stringToEnum(EventInterfaces, std.mem.span(global.interface)) orelse return;
            switch (events) {
                .wl_shm => {
                    context.shm = registry.bind(global.name, wl.Shm, 1) catch return;
                },
                .wl_compositor => {
                    context.compositor = registry.bind(global.name, wl.Compositor, 1) catch return;
                },
                .zwlr_layer_shell_v1 => {
                    context.layer_shell = registry.bind(global.name, zwlr.LayerShellV1, zwlr.LayerShellV1.generated_version) catch return;
                },
                .wl_output => {
                    const bound = registry.bind(
                        global.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch return;

                    context.outputs.append(bound) catch return;

                    var output_info = std.heap.page_allocator.create(OutputInfo) catch return;
                    output_info.* = OutputInfo{ .wl = bound };
                    context.output_info = output_info;
                },
                .zxdg_output_manager_v1 => {},
            }
        },
        .global_remove => {},
    }
}

fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, ev: zwlr.LayerSurfaceV1.Event, winsize: *[2]c_int) void {
    switch (ev) {
        .configure => |configure| {
            winsize.* = .{ @intCast(configure.width), @intCast(configure.height) };
            lsurf.setSize(configure.width, configure.height);
            lsurf.ackConfigure(configure.serial);
        },
        else => {},
    }
}
