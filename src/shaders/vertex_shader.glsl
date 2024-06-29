#version 330 core

layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aTexCoord;

out vec2 v_pos;

void main() {
    v_pos = aPos;

    vec4 position = vec4(aPos, 0.0, 1.0);
    position.xy = position.xy * 2. - 1.;
    position.y = -position.y;

    gl_Position = position;
}
