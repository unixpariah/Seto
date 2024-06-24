#version 330

layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aTex;

varying vec2 pos;

void main() {
    pos = aPos;

    vec4 position = vec4(aPos, 0.0, 1.0);
    position.xy = position.xy * 2. - 1.;

    gl_Position = position;
}
