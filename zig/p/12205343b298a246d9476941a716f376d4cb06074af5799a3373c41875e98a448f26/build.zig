const std = @import("std");

const EXAMPLES = [_][]const u8{
    "arc",
    "arc_negative",
    "bezier",
    "cairoscript",
    "clip",
    "clip_image",
    "compositing",
    "curve_rectangle",
    "curve_to",
    "dash",
    "ellipse",
    "fill_and_stroke2",
    "fill_style",
    "glyphs",
    "glyphs_path",
    "gradient",
    "grid",
    "group",
    "image",
    "image_pattern",
    "mask",
    "multi_segment_caps",
    "pango_simple",
    "pango_shape",
    "pango_twisted",
    "pythagoras_tree",
    "rounded_rectangle",
    "save_and_restore",
    "set_line_cap",
    "set_line_join",
    "sierpinski",
    "singular",
    "spiral",
    "spirograph",
    "surface_image",
    "surface_pdf",
    "surface_svg",
    // "surface_xcb",
    "text",
    "text_align_center",
    "text_extents",
    "three_phases",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opts = b.addOptions();
    opts.addOption(bool, "no-pango", b.option(bool, "no-pango", "disable pango support") orelse false);
    const opts_module = opts.createModule();

    const safety_module = b.addModule("safety", .{ .root_source_file = .{ .path = "src/safety.zig" } });

    var cairo_module = b.addModule("cairo", .{
        .root_source_file = .{ .path = "src/cairo.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = opts_module },
            .{ .name = "safety", .module = safety_module },
        },
    });
    var pango_module = b.addModule("pango", .{
        .root_source_file = .{ .path = "src/pango.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = opts_module },
            .{ .name = "cairo", .module = cairo_module },
            .{ .name = "safety", .module = safety_module },
        },
    });
    const pangocairo_module = b.addModule("pangocairo", .{
        .root_source_file = .{ .path = "src/pangocairo.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = opts_module },
            .{ .name = "cairo", .module = cairo_module },
            .{ .name = "pango", .module = pango_module },
            .{ .name = "safety", .module = safety_module },
        },
    });
    cairo_module.addImport("pangocairo", pangocairo_module);
    pango_module.addImport("pangocairo", pangocairo_module);

    const examples_step = b.step("examples", "Run all examples");
    inline for (EXAMPLES) |name| {
        const example = b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = "examples" ++ std.fs.path.sep_str ++ name ++ ".zig" },
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        example.root_module.addImport("cairo", cairo_module);
        example.linkSystemLibrary("cairo");

        const run_cmd = b.addRunArtifact(example);
        run_cmd.step.dependOn(b.getInstallStep());
        const desc = "Run the " ++ name ++ " example";
        const run_step = b.step(name, desc);
        run_step.dependOn(&run_cmd.step);

        example.root_module.addImport("pango", pango_module);
        example.linkSystemLibrary("pangocairo");

        examples_step.dependOn(&run_cmd.step);
    }
}
