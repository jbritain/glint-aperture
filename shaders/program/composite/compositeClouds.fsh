#version 450 core

#define CLOUD_NOISE_SAMPLERS
#define SKY_SAMPLERS

#include "/lib/common.glsl"

in vec2 uv;

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/clouds.glsl"

layout(location = 0) out vec4 color;

void main(){
    color = texture(sceneTex, uv);
    float depth = texture(solidDepthTex, uv).r;

    vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
    vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
    vec3 worldDir = normalize(feetPlayerPos);

    LightInteraction clouds = getClouds(feetPlayerPos, depth);

    color.rgb = color.rgb * clouds.transmittance + clouds.scattering;

}