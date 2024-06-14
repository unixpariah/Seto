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
    window: *wl.EglWindow,
    surface: c.EGLSurface,

    const Self = @This();

    pub fn new(display: *wl.Display, size: [2]c_int, surface: *wl.Surface) !Self {
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
                    c.EGL_ALPHA_SIZE,      8,
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

        const egl_window = wl.EglWindow.create(surface, size[0], size[1]) catch unreachable;
        return .{
            .display = egl_display,
            .config = config,
            .context = context,
            .window = egl_window,
            .surface = c.eglCreateWindowSurface(egl_display, config, @ptrCast(egl_window), null),
        };
    }

    pub fn changeCurrent(self: *Self) void {
        if (c.eglMakeCurrent(self.display, self.surface, self.surface, self.context) != c.EGL_TRUE) {
            std.process.exit(1);
        }
    }

    pub fn swapBuffers(self: *Self) void {
        if (c.eglSwapBuffers(self.display, self.surface) != c.EGL_TRUE) {
            std.debug.print("EGLError", .{});
            std.process.exit(1);
        }
    }

    pub fn clearScreen(self: *Self) void {
        self.changeCurrent();
        c.glClearColor(0, 0, 0, 0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        self.swapBuffers();
    }

    pub fn destroy(self: *Self) void {
        _ = c.eglDestroySurface(self.display, self.surface);
        _ = c.eglDestroyContext(self.display, self.context);
        _ = c.eglTerminate(self.display);
        self.window.destroy();
    }
};
