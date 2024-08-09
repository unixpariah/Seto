#version 460 core

layout(location = 0) out vec4 FragColor;

uniform vec4 startColor[400];
uniform vec4 midColor[400];
uniform vec4 endColor[400];
uniform float degrees[400];
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

  float angle = radians(degrees[fs_in.index]);
  vec2 rotatedUV = vec2(cos(angle) * uv.x - sin(angle) * uv.y,
                        sin(angle) * uv.x + cos(angle) * uv.y) +
                   0.5;

  float gradientFactor1 = smoothstep(0.0, 0.5, rotatedUV.x);
  float gradientFactor2 = smoothstep(0.5, 1.0, rotatedUV.x);

  vec4 color1 =
      mix(startColor[fs_in.index], midColor[fs_in.index], gradientFactor1);
  vec4 color2 =
      mix(midColor[fs_in.index], endColor[fs_in.index], gradientFactor2);
  vec4 finalColor = mix(color1, color2, gradientFactor2);

  FragColor = finalColor *
              texture(text, vec3(fs_in.texCoords, letterMap[fs_in.index])).r;
}
