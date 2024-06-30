pub usingnamespace @cImport({
    @cInclude("wayland-egl.h");
    @cInclude("EGL/egl.h");

    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("GL/gl.h");
    @cInclude("GL/glext.h");

    @cInclude("EGL/eglext.h");
    @cInclude("GLES2/gl2.h");

    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("fontconfig/fontconfig.h");
});
