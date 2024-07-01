#version 330 core

layout(location = 0) in vec2 in_pos;

uniform vec4 u_surface;

out vec2 out_pos;

void main() {
  vec2 position = vec2((in_pos - u_surface.xy) / (u_surface.zw - u_surface.xy));
  position.xy = position.xy * 2.0 - 1.0;
  position.y = -position.y;

  out_pos = position;

  gl_Position = vec4(position, 0.0, 1.0);
}
