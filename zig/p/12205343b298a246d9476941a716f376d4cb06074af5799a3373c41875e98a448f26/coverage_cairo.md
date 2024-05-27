# Progress made so far

|Objects|Number|Progress|
|:-:|:-:|:-:|
| Functions | 333/413 | ![](https://geps.dev/progress/81) |
| Types and Values | 60/88 | ![](https://geps.dev/progress/68) |

✔️ — done  
❌ — not done  
⬜️ — not required  
🕝 — incomplete/questionable

## [Drawing](https://www.cairographics.org/manual/cairo-drawing.html)
- ### [cairo_t](https://www.cairographics.org/manual/cairo-cairo-t.html) — The cairo drawing context
    ||||
    |:-:|:-:|:-:|
    | Functions | 60/60 | ![](https://geps.dev/progress/100) |
    | Types and Values | 8/8 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_save | ✔️ |⬜️  | ⬜️ | ✔️ |
    | cairo_restore | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_target | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_push_group | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_push_group_with_content | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pop_group | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_pop_group_to_source | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_group_target | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_set_source_rgb | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_source_rgba | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_source | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_source_surface | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_source | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_antialias | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_antialias | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_dash | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_dash_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_dash | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_fill_rule | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_fill_rule | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_line_cap | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_line_cap | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_line_join | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_line_join | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_line_width | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_line_width | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_miter_limit | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_miter_limit | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_operator | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_operator | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_tolerance | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_tolerance | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_clip | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_clip_preserve | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_clip_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_in_clip | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_reset_clip | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rectangle_list_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_copy_clip_rectangle_list | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_fill | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_fill_preserve | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_fill_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_in_fill | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mask | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mask_surface | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_paint | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_paint_with_alpha | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_stroke | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_stroke_preserve | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_stroke_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_in_stroke | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_copy_page | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_show_page | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [Paths](https://www.cairographics.org/manual/cairo-Paths.html) — Creating paths and manipulating path data
    ||||
    |:-:|:-:|:-:|
    | Functions | 21/21 | ![](https://geps.dev/progress/100) |
    | Types and Values | 3/3 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>
    
    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_copy_path | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_copy_path_flat | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_path_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_append_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_has_current_point | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_current_point | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_new_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_new_sub_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_close_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_arc | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_arc_negative | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_curve_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_line_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_move_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rectangle | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_glyph_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_text_path | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rel_curve_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rel_line_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rel_move_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_path_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    
    </details>

- ### [cairo_pattern_t](https://www.cairographics.org/manual/cairo-cairo-pattern-t.html) — Sources for drawing
    ||||
    |:-:|:-:|:-:|
    | Functions | 39/39 | ![](https://geps.dev/progress/100) |
    | Types and Values | 4/4 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_pattern_add_color_stop_rgb | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_add_color_stop_rgba | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_color_stop_count | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_get_color_stop_rgba | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_create_rgb | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pattern_create_rgba | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pattern_get_rgba | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_create_for_surface | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pattern_get_surface | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_create_linear | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pattern_get_linear_points | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_create_radial | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pattern_get_radial_circles | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_create_mesh | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_mesh_pattern_begin_patch |  |  |  |  |
    | cairo_mesh_pattern_end_patch | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_move_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_line_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_curve_to | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_set_control_point | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_set_corner_color_rgb | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_set_corner_color_rgba | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_get_patch_count | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_get_path | ✔️ | ⬜️ | 🕝 | ✔️ |
    | cairo_mesh_pattern_get_control_point | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_mesh_pattern_get_corner_color_rgba | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_pattern_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_pattern_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_set_extend | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_extend | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_set_filter | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_filter | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_set_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pattern_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_pattern_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [Regions](https://www.cairographics.org/manual/cairo-Regions.html) — Representing a pixel-aligned area
    ||||
    |:-:|:-:|:-:|
    | Functions | 23/23 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/2 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_region_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_region_create_rectangle | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_region_create_rectangles | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_region_copy | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_region_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_region_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_region_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_get_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_num_rectangles | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_get_rectangle | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_is_empty | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_contains_point | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_contains_rectangle | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_equal | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_translate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_region_intersect | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_intersect_rectangle | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_subtract | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_subtract_rectangle | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_union | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_union_rectangle | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_xor | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_region_xor_rectangle | ✔️ | ✔️ | ⬜️ | ✔️ |

    </details>

- ### [Transformations](https://www.cairographics.org/manual/cairo-Transformations.html) — Manipulating the current transformation matrix
    ||||
    |:-:|:-:|:-:|
    | Functions | 11/11 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_translate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scale | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_rotate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_transform | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_identity_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_user_to_device | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_user_to_device_distance | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_to_user | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_to_user_distance | ✔️ | ⬜️ | ⬜️ | ✔️ |


- ### [text](https://www.cairographics.org/manual/cairo-text.html) — Rendering text and glyphs
    ||||
    |:-:|:-:|:-:|
    | Functions | 24/24 | ![](https://geps.dev/progress/100) |
    | Types and Values | 5/5 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_select_font_face | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_font_size | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_font_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_font_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_font_options | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_font_options | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_set_font_face | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_font_face | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_set_scaled_font | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_get_scaled_font | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_show_text | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_show_glyphs | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_show_text_glyphs | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_text_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_glyph_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_toy_font_face_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_toy_font_face_get_family | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_toy_font_face_get_slant | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_toy_font_face_get_weight | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_glyph_allocate | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_glyph_free | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_text_cluster_allocate | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_text_cluster_free | ✔️ | ⬜️ | ✔️ | ✔️ |

    </details>

- ### [Raster Sources](https://www.cairographics.org/manual/cairo-Raster-Sources.html) — Supplying arbitrary image data
    ||||
    |:-:|:-:|:-:|
    | Functions | 11/11 | ![](https://geps.dev/progress/100) |
    | Types and Values | 5/5 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_pattern_create_raster_source | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_raster_source_pattern_set_callback_data | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_get_callback_data | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_set_acquire | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_get_acquire | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_set_snapshot | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_get_snapshot | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_set_copy | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_get_copy | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_set_finish | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_raster_source_pattern_get_finish | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [Tags and Links](https://www.cairographics.org/manual/cairo-Tags-and-Links.html) — Hyperlinks and document structure
    ||||
    |:-:|:-:|:-:|
    | Functions | 2/2 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/2 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_tag_begin | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_tag_end | ✔️ | ⬜️ | ⬜️ | 🕝 |

    </details>

## [Fonts](https://www.cairographics.org/manual/cairo-fonts.html)

- ### [cairo_font_face_t](https://www.cairographics.org/manual/cairo-cairo-font-face-t.html) — Base class for font faces
    ||||
    |:-:|:-:|:-:|
    | Functions | 7/7 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/2 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_font_face_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_font_face_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_font_face_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_face_get_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_face_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_face_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_font_face_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [cairo_scaled_font_t](https://www.cairographics.org/manual/cairo-cairo-scaled-font-t.html) — Font face at particular size and options
    ||||
    |:-:|:-:|:-:|
    | Functions | 17/17 | ![](https://geps.dev/progress/100) |
    | Types and Values | 3/3 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_scaled_font_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_scaled_font_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_scaled_font_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_scaled_font_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_text_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_glyph_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_text_to_glyphs | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_scaled_font_get_font_face | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_font_options | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_font_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_ctm | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_scale_matrix | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_scaled_font_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_scaled_font_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [cairo_font_options_t](https://www.cairographics.org/manual/cairo-cairo-font-options-t.html) — How a font should be rendered
    ||||
    |:-:|:-:|:-:|
    | Functions | 17/17 | ![](https://geps.dev/progress/100) |
    | Types and Values | 4/4 | ![](https://geps.dev/progress/100) |

    <details>
    <summary>Functions</summary>

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_font_options_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_font_options_copy | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_font_options_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_font_options_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_merge | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_equal | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_hash | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_set_antialias | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_get_antialias | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_set_subpixel_order | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_get_subpixel_order | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_set_hint_style | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_get_hint_style | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_set_hint_metrics | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_get_hint_metrics | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_set_variations | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_font_options_get_variations | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

- ### [FreeType Fonts](https://www.cairographics.org/manual/cairo-FreeType-Fonts.html) — Font support for FreeType
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/8 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/3 | ![](https://geps.dev/progress/0) |

- ### [Win32 Fonts](https://www.cairographics.org/manual/cairo-Win32-Fonts.html) — Font support for Microsoft Windows
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/8 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) |    

- ### [Quartz (CGFont) Fonts](https://www.cairographics.org/manual/cairo-Quartz-(CGFont)-Fonts.html) — Font support via CGFont on OS X
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/2 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) |   

- ### [User Fonts](https://www.cairographics.org/manual/cairo-User-Fonts.html) — Font support with font data provided by the user
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/9 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/5 | ![](https://geps.dev/progress/0) |  

## [Surfaces](https://www.cairographics.org/manual/cairo-fonts.html)

- ### [cairo_device_t](https://www.cairographics.org/manual/cairo-cairo-device-t.html) — interface to underlying rendering system
    ||||
    |:-:|:-:|:-:|
    | Functions | 18/18 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/2 | ![](https://geps.dev/progress/100) |  

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_device_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_device_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_device_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_finish | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_flush | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_get_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_device_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_acquire | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_device_release | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_device_observer_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_fill_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_glyphs_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_mask_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_paint_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_print | ✔️ | ⬜️ | ⬜️ | 🕝 |
    | cairo_device_observer_stroke_elapsed | ✔️ | ⬜️ | ⬜️ | 🕝 |

    </details>

- ### [cairo_surface_t](https://www.cairographics.org/manual/cairo-cairo-surface-t.html) — Base class for surfaces
    ||||
    |:-:|:-:|:-:|
    | Functions | 31/31 | ![](https://geps.dev/progress/100) |
    | Types and Values | 4/4 | ![](https://geps.dev/progress/100) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_surface_create_similar | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_surface_create_similar_image | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_surface_create_for_rectangle | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_surface_reference | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_surface_destroy | ✔️ | ⬜️ | ✔️ | ✔️ |
    | cairo_surface_status | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_finish | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_flush | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_device | ✔️ | ⬜️ | 🕝 | ✔️ |
    | cairo_surface_get_font_options | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_content | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_mark_dirty | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_mark_dirty_rectangle | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_set_device_offset | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_device_offset | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_device_scale | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_set_device_scale | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_set_fallback_resolution | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_fallback_resolution | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_get_reference_count | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_set_user_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_surface_get_user_data | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_copy_page | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_show_page | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_has_show_text_glyphs | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_set_mime_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_surface_get_mime_data | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_supports_mime_type | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_surface_map_to_image | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_surface_unmap_image | ✔️ | ⬜️ | ✔️ | ✔️ |

    </summary>

- ### [Image Surfaces](https://www.cairographics.org/manual/cairo-Image-Surfaces.html) — Rendering to memory buffers
    ||||
    |:-:|:-:|:-:|
    | Functions | 8/8 | ![](https://geps.dev/progress/100) |
    | Types and Values | 1/2 | ![](https://geps.dev/progress/50) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_image_surface_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_image_surface_create_for_data | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_image_surface_get_data | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_image_surface_get_format | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_image_surface_get_width | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_image_surface_get_height | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_image_surface_get_stride | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </summary>

- ### [PDF Surfaces](https://www.cairographics.org/manual/cairo-PDF-Surfaces.html) — Rendering PDF documents
    ||||
    |:-:|:-:|:-:|
    | Functions | 10/10 | ![](https://geps.dev/progress/100) |
    | Types and Values | 4/5 | ![](https://geps.dev/progress/80) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_pdf_surface_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pdf_surface_create_for_stream | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_pdf_surface_restrict_to_version | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_get_versions | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_version_to_string | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_surface_set_size | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_surface_add_outline | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_surface_set_metadata | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_surface_set_page_label | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_pdf_surface_set_thumbnail_size | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </summary>

- ### [PNG Support](https://www.cairographics.org/manual/cairo-PNG-Support.html) — Reading and writing PNG images
    ||||
    |:-:|:-:|:-:|
    | Functions | 4/4 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/3 | ![](https://geps.dev/progress/66) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_image_surface_create_from_png | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_image_surface_create_from_png_stream | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_surface_write_to_png | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_surface_write_to_png_stream | ✔️ | ✔️ | ⬜️ | ✔️ |

    </summary>

- ### [PostScript Surfaces](https://www.cairographics.org/manual/cairo-PostScript-Surfaces.html) — Rendering PostScript documents
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/11 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/2 | ![](https://geps.dev/progress/0) | 

- ### [Recording Surfaces](https://www.cairographics.org/manual/cairo-Recording-Surfaces.html) — Records all drawing operations
    ||||
    |:-:|:-:|:-:|
    | Functions | 3/3 | ![](https://geps.dev/progress/100) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_recording_surface_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_recording_surface_ink_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_recording_surface_get_extents | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </summary>

- ### [Win32 Surfaces](https://www.cairographics.org/manual/cairo-Win32-Surfaces.html) — Microsoft Windows surface support
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/7 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) | 

- ### [SVG Surfaces](https://www.cairographics.org/manual/cairo-SVG-Surfaces.html) — Rendering SVG documents
    ||||
    |:-:|:-:|:-:|
    | Functions | 7/7 | ![](https://geps.dev/progress/100) |
    | Types and Values | 2/3 | ![](https://geps.dev/progress/66) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_svg_surface_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_svg_surface_create_for_stream | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_svg_surface_get_document_unit | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_svg_surface_set_document_unit | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_svg_surface_restrict_to_version | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_svg_get_versions | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_svg_version_to_string | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </summary>

- ### [Quartz Surfaces](https://www.cairographics.org/manual/cairo-Quartz-Surfaces.html) — Rendering to Quartz surfaces
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/3 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) | 

- ### [XCB Surfaces](https://www.cairographics.org/manual/cairo-XCB-Surfaces.html) — X Window System rendering using the XCB library
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/10 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/2 | ![](https://geps.dev/progress/0) | 

- ### [XLib Surfaces](https://www.cairographics.org/manual/cairo-XLib-Surfaces.html) — X Window System rendering using XLib
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/14 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) | 

- ### [XLib-XRender Backend](https://www.cairographics.org/manual/cairo-XLib-XRender-Backend.html) — X Window System rendering using XLib and the X Render extension
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/2 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/1 | ![](https://geps.dev/progress/0) | 

- ### [Script Surfaces](https://www.cairographics.org/manual/cairo-Script-Surfaces.html) — Rendering to replayable scripts
    ||||
    |:-:|:-:|:-:|
    | Functions | 8/8 | ![](https://geps.dev/progress/100) |
    | Types and Values | 1/2 | ![](https://geps.dev/progress/50) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_script_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_script_create_for_stream | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_script_from_recording_surface | ✔️ | ✔️ | ⬜️ | ✔️ |
    | cairo_script_set_mode | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_script_get_mode | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_script_surface_create | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_script_surface_create_for_target | ✔️ | ✔️ | ✔️ | ✔️ |
    | cairo_script_write_comment | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </details>

## [Utilities](https://www.cairographics.org/manual/cairo-support.html)

- ### [cairo_matrix_t](https://www.cairographics.org/manual/cairo-cairo-matrix-t.html) — Generic matrix operations
    ||||
    |:-:|:-:|:-:|
    | Functions | 12/12 | ![](https://geps.dev/progress/100) |
    | Types and Values | 1/1 | ![](https://geps.dev/progress/100) | 

    <details>
    <summary>Functions</summary> 

    | Name | Exists | Errors | Safety | Doc |
    |:-|:-:|:-:|:-:|:-:|
    | cairo_matrix_init | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_init_identity | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_init_translate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_init_scale | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_init_rotate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_translate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_scale | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_rotate | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_invert | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_multiply | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_transform_distance | ✔️ | ⬜️ | ⬜️ | ✔️ |
    | cairo_matrix_transform_point | ✔️ | ⬜️ | ⬜️ | ✔️ |

    </summary>

- ### [Error handling](https://www.cairographics.org/manual/cairo-Error-handling.html) — Decoding cairo's status
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/2 | ![](https://geps.dev/progress/0) |
    | Types and Values | 1/1 | ![](https://geps.dev/progress/100) | 

- ### [Version Information](https://www.cairographics.org/manual/cairo-Version-Information.html) — Compile-time and run-time version checks.
    ||||
    |:-:|:-:|:-:|
    | Functions | 0/4 | ![](https://geps.dev/progress/0) |
    | Types and Values | 0/5 | ![](https://geps.dev/progress/0) | 

- ### [Types](https://www.cairographics.org/manual/cairo-Types.html) — Generic data types
    ||||
    |:-:|:-:|:-:|
    | Types and Values | 4/4 | ![](https://geps.dev/progress/100) | 
