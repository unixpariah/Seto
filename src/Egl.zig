const std = @import("std");
const c = @import("ffi");
const wl = @import("wayland").client.wl;
const math = @import("math");
const zgl = @import("zgl");

fn glMessageCallback(_: ?*const anyopaque, source: zgl.DebugSource, err_type: zgl.DebugMessageType, id: usize, severity: zgl.DebugSeverity, message: []const u8) void {
    std.debug.print("{} {} {} {} {s}\n", .{ source, err_type, id, severity, message });
}

pub fn getProcAddress(_: ?*const anyopaque, proc: [:0]const u8) ?*const anyopaque {
    return c.eglGetProcAddress(proc.ptr);
}

pub const EglSurface = struct {
    window: *wl.EglWindow,
    surface: c.EGLSurface,

    display: *c.EGLDisplay,
    config: *c.EGLConfig,
    context: *c.EGLContext,
    main_shader_program: zgl.Program,
    text_shader_program: zgl.Program,
    background_buffer: zgl.Buffer,
    gen_VBO: *[3]zgl.Buffer,
    UBO: zgl.Buffer,

    pub fn resize(self: *EglSurface, new_dimensions: [2]u32) void {
        self.window.resize(@intCast(new_dimensions[0]), @intCast(new_dimensions[1]), 0, 0);
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

    pub fn deinit(self: *EglSurface) void {
        self.background_buffer.delete();
        if (c.eglDestroySurface(self.display.*, self.surface) != c.EGL_TRUE) @panic("Failed to destroy egl surface");
        self.window.destroy();
    }
};

fn compileShader(alloc: std.mem.Allocator, shader_source: []const u8, shader: zgl.Shader, shader_program: zgl.Program) !void {
    shader.source(1, &[1][]const u8{shader_source});
    shader.compile();

    if (shader.get(.compile_status) == 0) {
        const info_log = shader.getCompileLog(alloc) catch @panic("TODO");
        std.log.err("{s}\n", .{info_log});
        alloc.free(info_log);
    }

    shader_program.attach(shader);
}

display: c.EGLDisplay,
config: c.EGLConfig,
context: c.EGLContext,
main_shader_program: zgl.Program,
text_shader_program: zgl.Program,
VAO: zgl.VertexArray,
VBO: [3]zgl.Buffer,
EBO: zgl.Buffer,

const Self = @This();

pub fn init(alloc: std.mem.Allocator, display: *wl.Display) !Self {
    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) return error.EGLError;
    const egl_display = c.eglGetPlatformDisplay(
        c.EGL_PLATFORM_WAYLAND_EXT,
        display,
        null,
    ) orelse return error.EGLError;

    var major: i32 = 0;
    var minor: i32 = 0;
    if (c.eglInitialize(egl_display, @ptrCast(&major), @ptrCast(&minor)) != c.EGL_TRUE) return error.EGLError;

    const config = egl_conf: {
        var config: c.EGLConfig = null;
        var n_config: i32 = 0;
        if (c.eglChooseConfig(
            egl_display,
            &[_]i32{
                c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
                c.EGL_RED_SIZE,        8,
                c.EGL_GREEN_SIZE,      8,
                c.EGL_BLUE_SIZE,       8,
                c.EGL_ALPHA_SIZE,      8,
                c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_BIT,
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
            c.EGL_CONTEXT_MAJOR_VERSION,       major,
            c.EGL_CONTEXT_MINOR_VERSION,       minor,
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

    zgl.loadExtensions(@as(?*const anyopaque, null), getProcAddress) catch @panic("extensions failed to load");

    zgl.enable(.blend);
    zgl.blendFunc(.src_alpha, .one_minus_src_alpha);
    zgl.enable(.multisample);

    if (@import("builtin").mode == .Debug) {
        zgl.enable(.debug_output);
        zgl.debugMessageCallback(@as(?*const anyopaque, null), glMessageCallback);
    }

    const main_vertex_source = @embedFile("shaders/main.vert");
    const main_fragment_source = @embedFile("shaders/main.frag");

    const main_vertex_shader = zgl.createShader(.vertex);
    const main_fragment_shader = zgl.createShader(.fragment);

    defer main_vertex_shader.delete();
    defer main_fragment_shader.delete();

    const main_shader_program = zgl.createProgram();

    try compileShader(alloc, main_vertex_source, main_vertex_shader, main_shader_program);
    try compileShader(alloc, main_fragment_source, main_fragment_shader, main_shader_program);
    main_shader_program.link();
    if (main_shader_program.get(.link_status) == 0) {
        const info_log = main_shader_program.getCompileLog(alloc) catch @panic("TODO");
        std.log.err("{s}\n", .{info_log});
        alloc.free(info_log);
        return error.ShaderLinkError;
    }

    const text_vertex_source = @embedFile("shaders/text.vert");
    const text_fragment_source = @embedFile("shaders/text.frag");

    const text_vertex_shader = zgl.createShader(.vertex);
    const text_fragment_shader = zgl.createShader(.fragment);

    defer text_vertex_shader.delete();
    defer text_fragment_shader.delete();

    const text_shader_program = zgl.createProgram();

    try compileShader(alloc, text_vertex_source, text_vertex_shader, text_shader_program);
    try compileShader(alloc, text_fragment_source, text_fragment_shader, text_shader_program);
    text_shader_program.link();

    if (text_shader_program.get(.link_status) == 0) {
        const info_log = text_shader_program.getCompileLog(alloc) catch @panic("TODO");
        std.log.err("{s}\n", .{info_log});
        alloc.free(info_log);
        return error.ShaderLinkError;
    }

    var VAO = zgl.genVertexArray();
    VAO.bind();
    zgl.enableVertexAttribArray(zgl.getAttribLocation(main_shader_program, "in_pos").?);
    zgl.enableVertexAttribArray(zgl.getAttribLocation(text_shader_program, "in_pos").?);

    var VBO: [3]zgl.Buffer = undefined;
    zgl.genBuffers(&VBO);

    // Selection VBO
    VBO[1].bind(.array_buffer);
    VBO[1].data(f32, &[1]f32{0} ** 8, .dynamic_draw);

    // Text VBO
    var vertices = [_]f32{
        0, 0,
        1, 0,
        0, 1,
        1, 1,
    };
    VBO[2].bind(.array_buffer);
    VBO[2].data(f32, &vertices, .static_draw);

    var EBO = zgl.genBuffer();
    var indices = [_]u32{
        0, 1, 3,
        3, 2, 0,
    };

    EBO.bind(.element_array_buffer);
    EBO.data(u32, &indices, .static_draw);

    return .{
        .display = egl_display,
        .config = config,
        .context = context,
        .main_shader_program = main_shader_program,
        .text_shader_program = text_shader_program,
        .VAO = VAO,
        .VBO = VBO,
        .EBO = EBO,
    };
}

pub fn surfaceInit(self: *Self, surface: *wl.Surface, size: [2]i32) !EglSurface {
    const egl_window = try wl.EglWindow.create(surface, size[0], size[1]);

    const egl_surface = c.eglCreatePlatformWindowSurface(
        self.display,
        self.config,
        egl_window,
        null,
    ) orelse return error.EGLError;

    const background_buffer = zgl.genBuffer();
    const UBO = zgl.genBuffer();

    return .{
        .window = egl_window,
        .surface = egl_surface,
        .display = &self.display,
        .config = &self.config,
        .context = &self.context,
        .main_shader_program = self.main_shader_program,
        .text_shader_program = self.text_shader_program,
        .background_buffer = background_buffer,
        .gen_VBO = &self.VBO,
        .UBO = UBO,
    };
}

pub fn deinit(self: *Self) void {
    self.EBO.delete();
    for (self.VBO) |VBO| VBO.delete();
    self.VAO.delete();
    if (c.eglDestroyContext(self.display, self.context) != c.EGL_TRUE) @panic("Failed to destroy egl context");
    if (c.eglTerminate(self.display) != c.EGL_TRUE) @panic("Failed to terminate egl");
}
