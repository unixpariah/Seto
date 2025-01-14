#version 450 core

in vec2 in_pos;

layout(std140) uniform UniformBlock {
  mat4 projection;
  vec4 startColor[2];
  vec4 endColor[2];
  float degrees[2];
};

out vec2 v_pos;

void main() {
  vec4 position = projection * vec4(in_pos, 0.0, 1.0);
  gl_Position = position;

  v_pos = position.xy;
}
