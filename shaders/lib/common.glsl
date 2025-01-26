#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/lib/common/samplers.glsl"
#include "/lib/common/syntax.glsl"
#include "/lib/common/material.glsl"
#include "/lib/common/spaceConversions.glsl"
#include "/lib/common/util.glsl"
#include "/lib/common/gbufferData.glsl"

vec3 sunDir = normalize(ap.celestial.sunPos);
vec3 worldSunDir = mat3(ap.camera.viewInv) * sunDir;

vec3 lightDir = normalize(ap.celestial.pos);
vec3 worldLightDir = mat3(ap.camera.viewInv) * lightDir;

struct LightInteraction {
  vec3 scattering;
  vec3 transmittance;
};

#endif // COMMON_GLSL
