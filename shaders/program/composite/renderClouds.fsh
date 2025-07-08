#version 450 core

uniform sampler2D sceneTex;

uniform sampler2D solidDepthTex;
uniform sampler2D previousDepthTex;

in vec2 uv;

#include "/lib/common.glsl"
#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/util/reproject.glsl"

layout(location = 0) out vec3 scattering;
layout(location = 1) out vec3 transmittance;

uniform sampler2D cloudTransmitTex;
uniform sampler2D cloudScatterTex;

void main(){
    float depth = texture(solidDepthTex, uv).r;
    vec3 previousScreenPos = reprojectScreen(vec3(uv, depth));
    float previousDepth = texture(previousDepthTex, uv).r;

    scattering = texture(cloudScatterTex, previousScreenPos.xy).rgb;
    transmittance = texture(cloudTransmitTex, previousScreenPos.xy).rgb;

    vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
    vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
    vec3 worldDir = normalize(feetPlayerPos);

    LightInteraction clouds = getClouds(feetPlayerPos, depth);

    float blend = (((previousDepth == 1.0) == (depth == 1.0))) ? 0.2 : 1.0;

    scattering = mix(scattering, clouds.scattering, blend);
    transmittance = mix(transmittance, clouds.transmittance, blend);
}