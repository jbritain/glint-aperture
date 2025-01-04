#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/lib/common/syntax.glsl"
#include "/lib/common/material.glsl"
#include "/lib/common/spaceConversions.glsl"
#include "/lib/common/util.glsl"

vec3 sunDir = normalize(sunPosition);
vec3 worldSunDir = mat3(playerModelViewInverse) * sunDir;

vec3 lightDir = normalize(shadowLightPosition);
vec3 worldLightDir = mat3(playerModelViewInverse) * lightDir;

#endif // COMMON_GLSL
