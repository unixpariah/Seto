#version 330 core

layout(location = 0) in vec2 a_pos;

out vec2 v_pos;

void main() {
    vec2 position = vec2(a_pos / vec2(1920, 1080));
    position.xy = position.xy * 2.0 - 1.0;
    position.y = -position.y;

    v_pos = position;

    gl_Position = vec4(position, 0.0, 1.0);
}
