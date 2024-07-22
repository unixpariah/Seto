#version 460 core

layout(location = 0) in vec4 in_pos;

layout(std140) uniform MyUniformBlock { mat4 projection; };

out vec2 v_pos;
out vec2 v_texcoords;

void main() {
  vec4 position = projection * vec4(in_pos.xy, 0.0, 1.0);
  gl_Position = position;

  v_pos = position.xy;
  v_texcoords = in_pos.zw;
}
