#ifndef ATMOSPHERIC_FOG_GLSL
#define ATMOSPHERIC_FOG_GLSL

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/sky.glsl"

vec3 atmosphericFog(vec3 color, vec3 playerPos){
  return color;
  float transmittance = clamp01(exp(-length(playerPos) * 0.00004));
  vec3 fogColor = skylightColor * henyeyGreenstein(0.0, 0.0);

  fogColor = mix(fogColor, getSky(normalize(playerPos), false), smoothstep(ap.camera.far, ap.camera.far * 2.0, length(playerPos)));

  color = mix(fogColor, color.rgb, transmittance);
  return color;
}

#endif // ATMOSPHERIC_FOG_GLSL