#version 450 core

layout(location = 0) in vec2 in_pos;

layout(std140) uniform UniformBlock {
  mat4 projection;
  vec4 startColor[2];
  vec4 endColor[2];
  float degrees[2];
};
uniform mat4 transform[400];

out VS_OUT {
  vec2 pos;
  vec2 texCoords;
  flat int index;
  vec4 startColor[2];
  vec4 endColor[2];
  float degrees[2];
}
vs_out;

void main() {
  vec4 position =
      projection * transform[gl_InstanceID] * vec4(in_pos, 0.0, 1.0);

  gl_Position = position;

  vs_out.pos = position.xy;
  vs_out.texCoords = in_pos;
  vs_out.index = gl_InstanceID;
  vs_out.startColor = startColor;
  vs_out.endColor = endColor;
  vs_out.degrees = degrees;
}
