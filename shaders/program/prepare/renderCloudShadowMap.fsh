#version 450 core

#define SKY_SAMPLERS
#define CLOUD_NOISE_SAMPLERS

#include "/lib/common.glsl"

in vec2 uv;

#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"

layout(location = 0) out vec3 transmit;

void main(){
  vec3 shadowScreenPos = vec3(uv, 1.0);
  vec4 shadowHomPos = inverse(ap.celestial.projection[3]) * vec4(shadowScreenPos * 2.0 - 1.0, 1.0);
  vec3 feetPlayerPos = (inverse(ap.celestial.view) * vec4(shadowHomPos.xyz / shadowHomPos.w, 1.0)).xyz;

  LightInteraction clouds = getClouds(feetPlayerPos, 1.0);
  transmit = clouds.transmittance;
  show(transmit);
}