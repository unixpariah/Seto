#version 450 core

layout(location = 0) in vec2 in_pos;

layout(std140, binding = 0) uniform UniformBlock { mat4 projection; };

out vec2 v_pos;

void main() {
  vec4 position = projection * vec4(in_pos, 0.0, 1.0);
  gl_Position = position;

  v_pos = position.xy;
}
