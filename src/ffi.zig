pub usingnamespace @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("freetype/ftoutln.h");
    @cInclude("freetype/ftsynth.h");
    @cInclude("freetype/ftstroke.h");
    @cInclude("fontconfig/fontconfig.h");

    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("GL/gl.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
});
