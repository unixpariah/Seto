const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const c = @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("GLES2/gl2.h");
    @cInclude("EGL/egl.h");
});

pub const EglSurface = struct {
    window: *wl.EglWindow,
    surface: c.EGLSurface,
    width: u32,
    height: u32,

    const Self = @This();

    pub fn resize(self: *Self, new_dimensions: [2]u32) void {
        self.width = new_dimensions[0];
        self.height = new_dimensions[1];
        self.window.resize(@intCast(self.width), @intCast(self.height), 0, 0);
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
        const egl_display = c.eglGetDisplay(@ptrCast(display)) orelse return error.EGLError;
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
                c.EGL_CONTEXT_MAJOR_VERSION,       4,
                c.EGL_CONTEXT_MINOR_VERSION,       3,
                c.EGL_CONTEXT_OPENGL_DEBUG,        c.EGL_TRUE,
                c.EGL_CONTEXT_OPENGL_PROFILE_MASK, c.EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
                c.EGL_NONE,
            },
        ) orelse return error.EGLError;

        if (c.eglMakeCurrent(
            egl_display,
            c.EGL_NO_SURFACE,
            c.EGL_NO_SURFACE,
            context,
        ) != c.EGL_TRUE) return error.EGLError;

        const vertex_shader_source =
            \\#version 330 core
            \\layout (location = 0) in vec3 position;
            \\void main() {
            \\  gl_Position = vec4(position.x, position.y, position.z, 1.0);
            \\}
        ;

        const fragment_shader_source =
            \\#version 330 core
            \\out vec4 color;
            \\void main() {
            \\  color = vec4(1.0f, 0.5f, 0.2f, 1.0f);
            \\}
        ;

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
        const egl_surface = c.eglCreateWindowSurface(self.display, self.config, @ptrCast(egl_window), null);

        return .{ .window = egl_window, .surface = egl_surface, .width = 0, .height = 0 };
    }

    pub fn changeCurrent(self: *Self, egl_surface: EglSurface) !void {
        if (c.eglMakeCurrent(
            self.display,
            egl_surface.surface,
            egl_surface.surface,
            self.context,
        ) != c.EGL_TRUE) return error.EGLError;
        c.glViewport(0, 0, @intCast(egl_surface.width), @intCast(egl_surface.height));
    }

    pub fn swapBuffers(self: *Self, egl_surface: EglSurface) !void {
        if (c.eglSwapBuffers(self.display, egl_surface.surface) != c.EGL_TRUE) return error.EGLError;
    }

    pub fn clearScreen(self: *Self) !void {
        try self.changeCurrent();
        c.glClearColor(0, 0, 0, 0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        try self.swapBuffers();
    }

    pub fn destroy(self: *Self) void {
        _ = c.eglDestroySurface(self.display, self.surface);
        _ = c.eglDestroyContext(self.display, self.context);
        _ = c.eglTerminate(self.display);
        self.window.destroy();
    }
};
