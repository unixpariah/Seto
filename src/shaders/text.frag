// #version 450 core

layout(location = 0) out vec4 FragColor;

uniform sampler2DArray text;
uniform int letterMap[LENGTH];
uniform int colorIndex[LENGTH];

in VS_OUT {
  vec2 pos;
  highp vec2 texCoords;
  flat int index;
  vec4 startColor[2];
  vec4 endColor[2];
  float degrees[2];
}
fs_in;

void main() {
  vec2 uv = fs_in.pos - 0.5;

  float angle = radians(fs_in.degrees[colorIndex[fs_in.index]]);
  vec2 rotatedUV = vec2(cos(angle) * uv.x - sin(angle) * uv.y,
                        sin(angle) * uv.x + cos(angle) * uv.y) +
                   0.5;

  float gradientFactor = smoothstep(0.0, 1.0, rotatedUV.x);
  vec4 color = mix(fs_in.startColor[colorIndex[fs_in.index]],
                   fs_in.endColor[colorIndex[fs_in.index]], gradientFactor);

  float sdf = texture(text, vec3(fs_in.texCoords.xy, letterMap[fs_in.index])).r;
  float edgeWidth = 0.25;
  float alpha = smoothstep(0.5 - edgeWidth, 0.5 + edgeWidth, sdf);

  FragColor = vec4(color.rgb, color.a * alpha);
}
