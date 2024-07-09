#version 460 core

layout(location = 0) in vec4 in_pos;

uniform vec4 u_surface;

out vec2 v_pos;
out vec2 v_texcoords;

void main() {
  vec2 position =
      mix(vec2(-1.0, 1.0), vec2(1.0, -1.0),
          (in_pos.xy - u_surface.xy) / (u_surface.zw - u_surface.xy));

  v_texcoords = in_pos.zw;
  v_pos = position;

  gl_Position = vec4(position, 0.0, 1.0);
}
