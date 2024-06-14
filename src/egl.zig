const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("GLES2/gl2.h");
    @cInclude("EGL/egl.h");
});

pub const Egl = struct {
    display: c.EGLDisplay,
    config: c.EGLConfig,
    context: c.EGLContext,

    const Self = @This();

    pub fn new(display: *wl.Display) !Self {
        const egl_display = c.eglGetDisplay(@ptrCast(display));
        if (c.eglInitialize(egl_display, null, null) != c.EGL_TRUE) return error.EGLError;

        const config = egl_conf: {
            var config: c.EGLConfig = undefined;
            var n_config: i32 = 0;
            if (c.eglChooseConfig(
                egl_display,
                &[_]i32{
                    c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
                    c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_BIT,
                    c.EGL_RED_SIZE,        8,
                    c.EGL_GREEN_SIZE,      8,
                    c.EGL_BLUE_SIZE,       8,
                    c.EGL_NONE,
                },
                &config,
                1,
                &n_config,
            ) != c.EGL_TRUE) return error.EGLError;
            break :egl_conf config;
        };

        const context = c.eglCreateContext(
            egl_display,
            config,
            c.EGL_NO_CONTEXT,
            &[_]i32{
                c.EGL_CONTEXT_CLIENT_VERSION, 2,
                c.EGL_NONE,
            },
        ) orelse return error.EGLError;

        return .{
            .display = egl_display,
            .config = config,
            .context = context,
        };
    }

    pub fn createSurface(self: *Self, surface: *wl.Surface, width: c_int, height: c_int) c.EGLSurface {
        const egl_window = wl.EglWindow.create(surface, width, height) catch unreachable;
        const egl_surface = c.eglCreateWindowSurface(self.display, self.config, @ptrCast(egl_window), null);
        if (c.eglMakeCurrent(self.display, egl_surface, egl_surface, self.context) != c.EGL_TRUE) {
            std.process.exit(1);
        }
        return egl_surface;
    }
};
