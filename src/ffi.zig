pub usingnamespace @cImport({
    @cInclude("EGL/egl.h");

    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("GL/gl.h");
    @cInclude("EGL/eglext.h");

    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("fontconfig/fontconfig.h");
});
