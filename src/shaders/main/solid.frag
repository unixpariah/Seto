#version 460 core

layout(location = 0) out vec4 FragColor;

uniform vec4 u_color;

void main() { FragColor = u_color; }
