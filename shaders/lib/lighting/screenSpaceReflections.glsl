#ifndef SSR_GLSL
#define SSR_GLSL

#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/atmosphere/sky.glsl"

vec3 getScreenSpaceReflections(out vec3 fresnel, vec3 viewPos, Material material, vec3 mappedNormal, float skyLightmap){
  if(material.roughness != 0.0){
    fresnel = vec3(0.0);
    return vec3(0.0);
  }

  fresnel = schlick(material, dot(mappedNormal, normalize(-viewPos)));
  if(maxVec3(fresnel) < 0.01){
    return vec3(0.0);
  }

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.frame.counter);

  vec3 reflectedDir = reflect(normalize(viewPos), mappedNormal);

  vec3 reflectedPos;
  if(rayIntersects(viewPos, reflectedDir, 8, jitter, true, reflectedPos, true, false)){
    return texture(previousSceneTex, reflectedPos.xy).rgb;
  } else {
    return getSky(mat3(ap.camera.viewInv) * reflectedDir, false) * skyLightmap;
  }
}

#endif // SSR_GLSL