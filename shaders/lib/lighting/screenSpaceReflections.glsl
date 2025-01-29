#ifndef SSR_GLSL
#define SSR_GLSL

#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/atmosphere/sky.glsl"

#define ROUGH_REFLECTION_SAMPLES 8

// by Zombye
// https://discordapp.com/channels/237199950235041794/525510804494221312/1118170604160421918
vec3 sampleVNDFGGX(
  vec3 viewerDirection, // Direction pointing towards the viewer in tangent space
  vec2 alpha, // Roughness parameter along X and Y of the distribution
  vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
  // Transform viewer direction to the hemisphere configuration
  viewerDirection = normalize(vec3(alpha * viewerDirection.xy, viewerDirection.z));

  // Sample a reflection direction off the hemisphere
  const float tau = 6.2831853; // 2 * pi
  float phi = tau * xy.x;
  float cosTheta = fma(1.0 - xy.y, 1.0 + viewerDirection.z, -viewerDirection.z);
  float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
  vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

  // Evaluate halfway direction
  // This gives the normal on the hemisphere
  vec3 halfway = reflected + viewerDirection;

  // Transform the halfway direction back to hemiellispoid configuation
  // This gives the final sampled normal
  return normalize(vec3(alpha * halfway.xy, halfway.z));
}

vec3 SSRSample(out vec3 fresnel, vec3 viewPos, Material material, vec3 mappedNormal, float skyLightmap){
  fresnel = schlick(material, dot(mappedNormal, normalize(-viewPos)));
  if(maxVec3(fresnel) < 0.01){
    return vec3(0.0);
  }

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.frame.counter);

  vec3 reflectedDir = reflect(normalize(viewPos), mappedNormal);

  vec3 reflectedPos;

  vec3 reflection;

  if(rayIntersects(viewPos, reflectedDir, 8, jitter, true, reflectedPos, true, false)){
    float LOD = clamp(pow(distance(viewSpaceToScreenSpace(viewPos) * 2.0 - 1.0, reflectedPos * 2.0 - 1.0), pow(1.0-sqrt(material.roughness),5.0) * 3.0) * 6.0, 0.0, 6.0); // LOD curve by x0nk

    reflection = texture(previousSceneTex, reflectedPos.xy, LOD).rgb;
  } else {
    reflection = getSky(mat3(ap.camera.viewInv) * reflectedDir, false) * skyLightmap;
  }

  if(material.metalID != NO_METAL){
    reflection *= material.albedo;
  }

  return reflection;
}

vec3 getScreenSpaceReflections(out vec3 fresnel, vec3 viewPos, Material material, vec3 mappedNormal, float skyLightmap){
  if(material.roughness > 0.5){
    fresnel = vec3(0.0);
    return vec3(0.0);
  }


  if(material.roughness <= rcp(255.0)){
    return SSRSample(fresnel, viewPos, material, mappedNormal, skyLightmap);
  } else {
    vec3 averageReflection = vec3(0.0);
    fresnel = vec3(0.0);

    mat3 tbn = frisvadTBN(mappedNormal);

    vec3 V = normalize(-viewPos);

    for(int i = 0; i < ROUGH_REFLECTION_SAMPLES; i++){
      vec3 noise = blueNoise(gl_FragCoord.xy / ap.game.screenSize, ap.frame.counter * ROUGH_REFLECTION_SAMPLES + i).xyz;

      vec3 roughNormal = tbn * (sampleVNDFGGX(V * tbn, vec2(material.roughness), noise.xy));
      
      vec3 tempFresnel;
      averageReflection += SSRSample(tempFresnel, viewPos, material, roughNormal, skyLightmap);
      fresnel += tempFresnel;
    }

    averageReflection /= ROUGH_REFLECTION_SAMPLES;
    fresnel /= ROUGH_REFLECTION_SAMPLES;
    return averageReflection;
  }
}

#endif // SSR_GLSL