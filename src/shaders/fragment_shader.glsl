#version 460

precision mediump float;

uniform vec4 u_Color;
out vec4 FragColor;

void main() {
  FragColor = u_Color;
}
