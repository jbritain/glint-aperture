#ifndef SSR_GLSL
#define SSR_GLSL

#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/atmosphere/sky.glsl"

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
  if(rayIntersects(viewPos, reflectedDir, 8, jitter, true, reflectedPos, true, false)){
    return texture(previousSceneTex, reflectedPos.xy).rgb;
  } else {
    return getSky(mat3(ap.camera.viewInv) * reflectedDir, false) * skyLightmap;
  }
}

vec3 getScreenSpaceReflections(out vec3 fresnel, vec3 viewPos, Material material, vec3 mappedNormal, float skyLightmap){
  if(material.roughness > 0.5){
    fresnel = vec3(0.0);
    return vec3(0.0);
  }


  if(material.roughness == 0){
    return SSRSample(fresnel, viewPos, material, mappedNormal, skyLightmap);
  } else {
    vec3 averageReflection = vec3(0.0);
    fresnel = vec3(0.0);

    mat3 tbn = frisvadTBN(mappedNormal);

    vec3 V = normalize(-viewPos);

    for(int i = 0; i < 8; i++){
      vec3 noise = blueNoise(gl_FragCoord.xy / ap.game.screenSize, ap.frame.counter).xyz;

      vec3 roughNormal = tbn * (sampleVNDFGGX(V * tbn, vec2(material.roughness), noise.xy));
      
      vec3 tempFresnel;
      averageReflection += SSRSample(tempFresnel, viewPos, material, roughNormal, skyLightmap);
      fresnel += tempFresnel;
    }

    averageReflection /= 8;
    fresnel /= 8;
    return averageReflection;
  }
}

#endif // SSR_GLSL