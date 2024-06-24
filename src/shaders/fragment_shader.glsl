#version 330

precision mediump float;

uniform vec4 u_Color1;
uniform vec4 u_Color2;
uniform float u_Degrees;

varying vec2 pos;

void main() {
    vec2 uv = pos.xy;

    vec2 origin = vec2(0.5, 0.5);
    uv -= origin;

    float angle = radians(90.0) - radians(u_Degrees) + atan(uv.y, uv.x);

    uv = vec2(cos(angle) * length(uv), sin(angle) * length(uv)) + origin;

    gl_FragColor = mix(u_Color1, u_Color2, smoothstep(0.0, 1.0, uv.x));
}
