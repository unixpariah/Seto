#version 330 core

precision mediump float;

uniform vec4 u_startcolor;
uniform vec4 u_endcolor;
uniform float u_degrees;

varying vec2 v_pos;

void main() {
    vec2 uv = v_pos.xy;

    uv -= 0.5;

    float angle = radians(90.0) - radians(u_degrees) + atan(uv.y, uv.x);

    uv = vec2(cos(angle) * length(uv), sin(angle) * length(uv)) + 0.5;

    gl_FragColor = mix(u_startcolor, u_endcolor, smoothstep(0.0, 1.0, uv.x));
}
