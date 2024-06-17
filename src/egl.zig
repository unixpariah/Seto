const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const c = @cImport({
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
    @cInclude("GLES2/gl2.h");
});

pub const EglSurface = struct {
    window: *wl.EglWindow,
    surface: c.EGLSurface,
    width: f32,
    height: f32,

    const Self = @This();

    pub fn drawLine(self: *Self, line: [4]i32) void {
        const vertices = [_]f32{
            2 * (@as(f32, @floatFromInt(line[0])) / self.width) - 1,
            2 * ((self.height - @as(f32, @floatFromInt(line[1]))) / self.height) - 1,
            2 * (@as(f32, @floatFromInt(line[2])) / self.width) - 1,
            2 * ((self.height - @as(f32, @floatFromInt(line[3]))) / self.height) - 1,
        };

        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrCast(&vertices));
        c.glEnableVertexAttribArray(0);

        c.glDrawArrays(c.GL_LINES, 0, 2);
    }

    pub fn resize(self: *Self, new_dimensions: [2]u32) void {
        self.width = @floatFromInt(new_dimensions[0]);
        self.height = @floatFromInt(new_dimensions[1]);
        self.window.resize(@intFromFloat(self.width), @intFromFloat(self.height), 0, 0);
    }

    pub fn getEglError(_: *Self) !void {
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

pub const Egl = struct {
    display: c.EGLDisplay,
    config: c.EGLConfig,
    context: c.EGLContext,
    shader_program: c_uint,

    const Self = @This();

    pub fn new(display: *wl.Display) !Self {
        if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) return error.EGLError;
        const egl_display = c.eglGetPlatformDisplay(
            c.EGL_PLATFORM_WAYLAND_EXT,
            @ptrCast(display),
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
                    c.EGL_RED_SIZE,        8,
                    c.EGL_GREEN_SIZE,      8,
                    c.EGL_BLUE_SIZE,       8,
                    c.EGL_ALPHA_SIZE,      8,
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
                c.EGL_CONTEXT_CLIENT_VERSION, 2,
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
            std.log.err("{s}\n", .{info_log});
            return error.EGLError;
        }

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
            @ptrCast(egl_window),
            null,
        ) orelse return error.EGLError;

        return .{ .window = egl_window, .surface = egl_surface, .width = 0, .height = 0 };
    }

    pub fn makeCurrent(self: *Self, egl_surface: EglSurface) !void {
        if (c.eglMakeCurrent(
            self.display,
            egl_surface.surface,
            egl_surface.surface,
            self.context,
        ) != c.EGL_TRUE) return error.EGLError;
        c.glViewport(0, 0, @intFromFloat(egl_surface.width), @intFromFloat(egl_surface.height));
    }

    pub fn swapBuffers(self: *Self, egl_surface: EglSurface) !void {
        if (c.eglSwapBuffers(self.display, egl_surface.surface) != c.EGL_TRUE) return error.EGLError;
    }

    pub fn destroy(self: *Self) void {
        _ = c.eglDestroySurface(self.display, self.surface);
        _ = c.eglDestroyContext(self.display, self.context);
        _ = c.eglTerminate(self.display);
        self.window.destroy();
    }
};
