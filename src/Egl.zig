const std = @import("std");
const c = @import("ffi.zig");
const wl = @import("wayland").client.wl;

pub const EglSurface = struct {
    window: *wl.EglWindow,
    surface: c.EGLSurface,
    width: f32,
    height: f32,

    display: *c.EGLDisplay,
    config: *c.EGLConfig,
    context: *c.EGLContext,
    shader_program: *c_uint,

    pub fn resize(self: *EglSurface, new_dimensions: [2]u32) void {
        self.width = @floatFromInt(new_dimensions[0]);
        self.height = @floatFromInt(new_dimensions[1]);
        self.window.resize(@intFromFloat(self.width), @intFromFloat(self.height), 0, 0);
    }

    pub fn getEglError(_: *EglSurface) !void {
        switch (c.eglGetError()) {
            c.EGL_SUCCESS => return,
            c.GL_INVALID_ENUM => return error.GLInvalidEnum,
            c.GL_INVALID_VALUE => return error.GLInvalidValue,
            c.GL_INVALID_OPERATION => return error.GLInvalidOperation,
            c.GL_INVALID_FRAMEBUFFER_OPERATION => return error.GLInvalidFramebufferOperation,
            c.GL_OUT_OF_MEMORY => return error.OutOfMemory,
            else => return error.UnknownEglError,
        }
    }

    pub fn makeCurrent(self: *const EglSurface) !void {
        if (c.eglMakeCurrent(
            self.display.*,
            self.surface,
            self.surface,
            self.context.*,
        ) != c.EGL_TRUE) return error.EGLError;
    }

    pub fn swapBuffers(self: *const EglSurface) !void {
        if (c.eglSwapBuffers(self.display.*, self.surface) != c.EGL_TRUE) return error.EGLError;
    }

    pub fn destroy(self: *EglSurface) !void {
        if (c.eglDestroySurface(self.display.*, self.surface) != c.EGL_TRUE) return error.DestroyError;
        self.window.destroy();
    }
};

fn compileShader(shader_source: []const u8, shader: c_uint, shader_program: c_uint) !void {
    c.glShaderSource(
        shader,
        1,
        @ptrCast(&shader_source),
        &[_]c_int{@as(c_int, @intCast(shader_source.len))},
    );

    c.glCompileShader(shader);

    var success: u32 = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, @ptrCast(&success));
    if (success != c.GL_TRUE) {
        var info_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader, 512, null, @ptrCast(&info_log));
        std.log.err("{s}\n", .{info_log});
        return error.EGLError;
    }

    c.glAttachShader(shader_program, shader);
}

display: c.EGLDisplay,
config: c.EGLConfig,
context: c.EGLContext,
shader_program: c_uint,

const Self = @This();

pub fn new(display: *wl.Display) !Self {
    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) return error.EGLError;
    const egl_display = c.eglGetPlatformDisplay(
        c.EGL_PLATFORM_WAYLAND_EXT,
        display,
        null,
    ) orelse return error.EGLError;

    if (c.eglInitialize(egl_display, null, null) != c.EGL_TRUE) return error.EGLError;

    const config = egl_conf: {
        var config: c.EGLConfig = undefined;
        var n_config: i32 = 0;
        if (c.eglChooseConfig(
            egl_display,
            &[_]i32{
                c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
                c.EGL_RED_SIZE,        1,
                c.EGL_GREEN_SIZE,      1,
                c.EGL_BLUE_SIZE,       1,
                c.EGL_ALPHA_SIZE,      1,
                c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_ES2_BIT,
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
            c.EGL_CONTEXT_CLIENT_VERSION, 3,
            c.EGL_NONE,
        },
    ) orelse return error.EGLError;

    if (c.eglMakeCurrent(
        egl_display,
        c.EGL_NO_SURFACE,
        c.EGL_NO_SURFACE,
        context,
    ) != c.EGL_TRUE) return error.EGLError;

    const vertex_shader_source = @embedFile("shaders/vertex_shader.glsl");
    const fragment_shader_source = @embedFile("shaders/fragment_shader.glsl");

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    defer c.glDeleteShader(vertex_shader);
    defer c.glDeleteShader(fragment_shader);

    const shader_program = c.glCreateProgram();

    try compileShader(vertex_shader_source, vertex_shader, shader_program);
    try compileShader(fragment_shader_source, fragment_shader, shader_program);

    c.glLinkProgram(shader_program);

    var link_success: u32 = undefined;
    c.glGetProgramiv(shader_program, c.GL_LINK_STATUS, @ptrCast(&link_success));
    if (link_success != c.GL_TRUE) {
        var info_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader_program, 512, null, @ptrCast(&info_log));
        return error.EGLError;
    }

    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glEnableVertexAttribArray(0);
    c.glUseProgram(shader_program);

    return .{
        .display = egl_display,
        .config = config,
        .context = context,
        .shader_program = shader_program,
    };
}

pub fn newSurface(self: *Self, surface: *wl.Surface, size: [2]c_int) !EglSurface {
    const egl_window = try wl.EglWindow.create(surface, size[0], size[1]);

    const egl_surface = c.eglCreatePlatformWindowSurface(
        self.display,
        self.config,
        egl_window,
        null,
    ) orelse return error.EGLError;

    return .{
        .window = egl_window,
        .surface = egl_surface,
        .width = 0,
        .height = 0,
        .display = &self.display,
        .config = &self.config,
        .context = &self.context,
        .shader_program = &self.shader_program,
    };
}

pub fn destroy(self: *Self) !void {
    if (c.eglDestroyContext(self.display, self.context) != c.EGL_TRUE) return error.DestroyError;
    if (c.eglTerminate(self.display) != c.EGL_TRUE) return error.TerminateError;
}
