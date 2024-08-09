#version 460 core

layout(location = 0) out vec4 FragColor;

uniform vec4 color[400];
uniform sampler2DArray text;
uniform int letterMap[400];

in VS_OUT {
  vec2 texCoords;
  flat int index;
}
fs_in;

void main() {
  FragColor = color[fs_in.index] *
              texture(text, vec3(fs_in.texCoords, letterMap[fs_in.index])).r;
}
