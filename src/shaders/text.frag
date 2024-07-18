#version 460 core

layout(location = 0) out vec4 FragColor;

uniform vec4 u_startcolor;
uniform vec4 u_endcolor;
uniform float u_degrees;
uniform sampler2D text;

in vec2 v_pos;
in vec2 v_texcoords;

void main() {
  vec2 uv = v_pos - 0.5;

  float angle = radians(u_degrees);
  vec2 rotatedUV = vec2(cos(angle) * uv.x - sin(angle) * uv.y,
                        sin(angle) * uv.x + cos(angle) * uv.y) +
                   0.5;

  float gradientFactor = smoothstep(0.0, 1.0, rotatedUV.x);
  vec4 color = mix(u_startcolor, u_endcolor, gradientFactor);

  FragColor = color * texture(text, v_texcoords).r;
}
