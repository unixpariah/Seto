# giza

An attempt to make a binding for the popular [cairo](https://gitlab.freedesktop.org/cairo/cairo) and [pango](https://gitlab.gnome.org/GNOME/pango) graphics libraries with some idiomatic Zig elements (and some that will make true Zig enjoyers' skin crawl).

Many thanks to [jackdbd](https://github.com/jackdbd) for his [implementation](https://github.com/jackdbd/zig-cairo) of similar binding.

Zig version is 0.12.0.

## Quick start

1. Add giza as a dependency in your build.zig.zon as follows:

    ```diff
    .{
        .name = "your-project",
        .version = "1.0.0",
        .dependencies = .{
    +       .giza = .{
    +           .url = "https://github.com/koenigskraut/giza/archive/refs/tags/0.1.0.tar.gz",
    +           .hash = "12202e1b6ae20694324cef241beacaa745ee9e2611cda002830bb0ee681791970ffd",
    +       },
        },
    }
    ```

2. In your build.zig add giza as a dependency and attach its modules to your project:

    ```diff
    const std = @import("std");

    pub fn build(b: *std.Build) void {
        const target = b.standardTargetOptions(.{});
        const optimize = b.standardOptimizeOption(.{});

    +   const opts = .{ .target = target, .optimize = optimize };
    +   const dep = b.dependency("giza", opts);
    +
    +   const cairo_module = dep.module("cairo");
    +   const pango_module = dep.module("pango");
    +   const pangocairo_module = dep.module("pangocairo");

        const exe = b.addExecutable(.{
            .name = "test",
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
    +   exe.addModule("cairo", cairo_module);
    +   exe.addModule("pango", pango_module);
    +   exe.addModule("pangocairo", pangocairo_module);
    +   exe.linkSystemLibrary("pangocairo"); // if you need both cairo and pango, use this
        exe.install();

        ...
    }
    ```

Then you can check cairo website for reference, [samples](https://www.cairographics.org/samples/) section in particular. You will find ports of these snippets to Zig along with some other examples in giza [examples](https://github.com/koenigskraut/giza/blob/master/examples).

## Killer features

There are just the two of them, but what are these two!

### Safety checks

**cairo** sometimes returns allocated objects with user-managed lifetime, take for example:
```zig
const surface = try cairo.ImageSurface.create(.argb32, 600, 400); // cairo.ImageSurface with alpha 600x400px
```
`surface` is owned by user and should be destroyed at some point with `surface.destroy()`. It can be done nicely with Zig `defer` pattern:
```zig
const surface = try cairo.ImageSurface.create(.argb32, 600, 400);
defer surface.destroy();
```
But what if we can't do this? Let's see some example:
```zig
const cairo = @import("cairo");

test "safety" {
    const surface = try cairo.ImageSurface.create(.argb32, 600, 400);
    _ = surface; // surface should be destroyed somewhere else, but we forgot
}
```
Run it:
```bash
$ zig build test
run test: error: [giza] (err): Leak detected! ImageSurface@1cc4470 leaked:
/some/path/to/safety_test.zig:4:50: 0x235821 in test.safety (test)
    const surface = try cairo.ImageSurface.create(.argb32, 600, 400);
                                                 ^
...
Build Summary: 1/3 steps succeeded; 1 failed; 1/1 tests passed (disable with --summary none)
test transitive failure
└─ run test failure
```
Yes, **giza** detected a leak, printed stacktrace and panicked at return of the program, just like if it was a native Zig allocator leak!

Since we are linking libc anyway, I just interject some pointer counting in `create()`/`.reference()`/`.destroy()` functions and check for leaks with `atexit()` at the end. This happens only in debug and shouldn't be a performance issue then.

### `opaque` types

We have a C object, but what we want is a native one. Popular pattern: pointer to C object is stored as a field of the native struct/class and passed under the hood to C functions. That's fine, but can we do better?

Thanks to Zig's easy C interop, in **giza** there is no such pattern. All C objects behave like native ones. What are advantages and should you care? Let's see.

Every function in **giza**, that returns object with `.status()` method **and** could set it into an error state, checks its status and raises error immediately. It's not always the intended behavoir: **cairo** safely allows errors to propagate in these cases, plus it's overhead.

So for example let's create `ImageSurface` unsafely and manage it manually:
```zig
const std = @import("std");
const cairo = @import("cairo");
const c = @cImport(@cInclude("cairo.h"));

test "interop 1" {
    const surface_c = c.cairo_image_surface_create_from_png("does_not_exist.png").?; // cairo usually don't return null objects
    defer c.cairo_surface_destroy(surface_c);

    const image: *cairo.ImageSurface = @ptrCast(surface_c);
    try std.testing.expect(image.status() == .FileNotFound);
}
```
We can use prepared C functions from `cairo` module to avoid pointer casting:
```zig
test "interop 2" {
    const image = cairo_image_surface_create_from_png("does_not_exist.png").?;
    defer cairo.c.cairo_surface_destroy(image);
    try std.testing.expect(image.status() == .FileNotFound);
}
```
**giza**'s matrix functions return matrices by value:
```zig
var m = cairo.Matrix.identity();
```
`m` is `cairo.Matrix` which is an `extern struct` of 6 `f64` fields. But if you want, you can use underlying C function directly:
```zig
const cairo = @import("cairo");
const c = @cImport(@cInlude("cairo.h"));

test "interop 3" {
    var m: cairo.Matrix = undefined;
    c.cairo_matrix_init_identity(@ptrCast(&m));
    ...
}
```
or with `giza`'s prepared `extern fn`s:
```zig
test "interop 4" {
    var m: cairo.Matrix = undefined;
    cairo.c.cairo_matrix_init_identity(&m);
    ...
}
```
Every C object in **giza** is a valid Zig `opaque`/`extern struct`/`enum`, so you can call C functions with them like nothing yourself!

## Coverage and progress

Cairo is somewhat covered (info [here](https://github.com/koenigskraut/giza/blob/master/coverage_cairo.md)), current progress is 80.6% regarding **cairo** its functionality, __*but*__ it should work already. The only missing parts are font support for FreeType/Windows etc. and real devices (other than script one). If you only need cairo to write some PNG/PDF/SVG files, that is already covered: see [examples](https://github.com/koenigskraut/giza/tree/master/examples). Further progress is planned, but that would require using header files, which this wrapping has avoided so far, so we'll see.

Pango support is really lacking for now, but there is basic support (see [this](https://github.com/koenigskraut/giza/blob/master/examples/pango_simple.zig) and [this](https://github.com/koenigskraut/giza/blob/master/examples/pango_shape.zig)).
