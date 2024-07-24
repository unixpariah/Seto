#version 460 core

layout(location = 0) in vec2 in_pos;

layout(std140) uniform UniformBlock { mat4 projection; };
uniform mat4 transform;

out VS_OUT {
  vec2 pos;
  vec2 texCoords;
}
vs_out;

void main() {
  vec4 position = projection * transform * vec4(in_pos, 0.0, 1.0);
  gl_Position = position;

  vs_out.pos = position.xy;
  vs_out.texCoords = in_pos;
}
