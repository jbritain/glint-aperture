#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#define VOLUMETRIC_WATER_SAMPLES 8

#include "/lib/buffers/sceneData.glsl"
#include "/lib/util/shadowSpace.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/voxel/voxelMap.glsl"

LightInteraction waterFog(vec3 a, vec3 b){
  LightInteraction interact;
  interact.transmittance = vec3(1.0);
  interact.scattering = vec3(0.0);

  vec3 dir = normalize(b - a);
  float stepLength = distance(a, b) / float(VOLUMETRIC_WATER_SAMPLES);

  vec3 rayStep = dir * stepLength;

  vec3 rayPos = a;

  rayPos += blueNoise(gl_FragCoord.xy / ap.game.screenSize, ap.time.frames).r;

  vec3 stepTransmittance = exp(-WATER_ABSORPTION * WATER_DENSITY * stepLength);

  float sunPhase = henyeyGreenstein(0.6, dot(dir, mat3(ap.camera.viewInv) * normalize(ap.celestial.pos)));

  for(int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++, rayPos += rayStep){
    int cascade;
    vec3 shadowScreenPos = getShadowScreenPos(rayPos, cascade);
    vec3 radiance = sampleShadow(shadowScreenPos, cascade, rayPos) * sunlightColor * sunPhase;
    radiance += skylightColor * ap.camera.brightness.y * isotropicPhase;

    vec3 voxelPos = mapVoxelPosInterp(rayPos - ap.camera.pos);
    if(clamp01(voxelPos) == voxelPos){
      vec3 blocklightColor = vec3(0.0);
      if(EVEN_FRAME){
        blocklightColor = textureLod(floodFillVoxelMapTex2, voxelPos, 0).rgb / FLOODFILL_SCALING;
      } else {
        blocklightColor = textureLod(floodFillVoxelMapTex1, voxelPos, 0).rgb / FLOODFILL_SCALING;
      }
      radiance += blocklightColor * isotropicPhase;
    }

    vec3 integScatter = (radiance - radiance * clamp01(stepTransmittance)) / (WATER_ABSORPTION * WATER_DENSITY);
    interact.scattering += integScatter * interact.transmittance;
    interact.transmittance *= stepTransmittance;
  }

  // show(interact.scattering);

  return interact;
}

#endif