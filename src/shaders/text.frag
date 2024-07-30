#version 460 core

layout(location = 0) out vec4 FragColor;

uniform vec4 u_startcolor;
uniform vec4 u_endcolor;
uniform float u_degrees;
uniform sampler2DArray text;
uniform int letterMap[400];

in VS_OUT {
  vec2 pos;
  vec2 texCoords;
  flat int index;
}
fs_in;

void main() {
  vec2 uv = fs_in.pos - 0.5;

  float angle = radians(u_degrees);
  vec2 rotatedUV = vec2(cos(angle) * uv.x - sin(angle) * uv.y,
                        sin(angle) * uv.x + cos(angle) * uv.y) +
                   0.5;

  float gradientFactor = smoothstep(0.0, 1.0, rotatedUV.x);
  vec4 color = mix(u_startcolor, u_endcolor, gradientFactor);

  FragColor =
      color * texture(text, vec3(fs_in.texCoords.xy, letterMap[fs_in.index])).r;
}
