#version 450 core

#include "/lib/common.glsl"

in vec2 uv;

layout(location = 0) out vec3 color;

uniform sampler2D cloudTransmitTex;
uniform sampler2D cloudScatterTex;

void main(){
    vec3 scatter = textureLod(cloudScatterTex, uv, 0).rgb;
    vec3 transmit = textureLod(cloudTransmitTex, uv, 0).rgb;

    color = texture(sceneTex, uv).rgb;

    color = color * transmit + scatter;
}