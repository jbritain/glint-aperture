#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/lib/common/syntax.glsl"
#include "/lib/common/material.glsl"
#include "/lib/common/spaceConversions.glsl"
#include "/lib/common/util.glsl"
#include "/lib/common/gbufferData.glsl"
#include "/lib/common/debug.glsl"

vec3 sunDir = normalize(ap.celestial.sunPos);
vec3 worldSunDir = mat3(ap.camera.viewInv) * sunDir;

vec3 lightDir = normalize(ap.celestial.pos);
vec3 worldLightDir = mat3(ap.camera.viewInv) * lightDir;

struct LightInteraction {
  vec3 scattering;
  vec3 transmittance;
};

struct ShadowMask {
  bool water;
};

uint encodeShadowMask(ShadowMask mask){
  uint encodedMask = 0;
  if(mask.water){
    encodedMask = 1;
  }

  return encodedMask;
}

ShadowMask decodeShadowMask(uint encodedMask){
  ShadowMask mask;
  mask.water = encodedMask == 1;

  return mask;
}

const vec3 WATER_ABSORPTION = vec3(0.5, 0.17, 0.1);
const vec3 WATER_SCATTERING = vec3(0.31, 0.62, 0.68);
const vec3 WATER_DENSITY = vec3(0.5);
const vec3 WATER_EXCTINCTION = WATER_ABSORPTION + WATER_SCATTERING;

#define EVEN_FRAME ap.time.frames % 2 == 0

#define FLOODFILL_SCALING 4.0

#endif // COMMON_GLSL
