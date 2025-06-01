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

  rayPos += blueNoise(gl_FragCoord.xy / ap.game.screenSize, ap.time.frames).r * rayStep;
  vec3 stepTransmittance = exp(-stepLength * WATER_EXCTINCTION * WATER_DENSITY);

  float sunPhase = henyeyGreenstein(0.6, dot(dir, mat3(ap.camera.viewInv) * normalize(ap.celestial.pos)));

  for(int i = 0; i < VOLUMETRIC_WATER_SAMPLES; i++, rayPos += rayStep){
    int cascade;
    vec3 shadowScreenPos = getShadowScreenPos(rayPos, cascade);

    // sunlight contribution
    vec3 radiance = vec3(0.0);
    if(clamp01(shadowScreenPos) == shadowScreenPos){
      radiance = sampleShadow(shadowScreenPos, cascade, rayPos) * sunlightColor * sunPhase;
    } else {
      radiance = ap.camera.brightness.y * sunlightColor * sunPhase;
    }

    // skylight contribution
    radiance += skylightColor * ap.camera.brightness.y * isotropicPhase;

    // blocklight contribution
    vec3 voxelPos = mapVoxelPosInterp(rayPos - ap.camera.pos);
    if(clamp01(voxelPos) == voxelPos){
      vec3 blocklightColor = vec3(0.0);
      if(EVEN_FRAME){
        blocklightColor = textureLod(floodFillVoxelMapTex2, voxelPos, 0).rgb / FLOODFILL_SCALING;
      } else {
        blocklightColor = textureLod(floodFillVoxelMapTex1, voxelPos, 0).rgb / FLOODFILL_SCALING;
      }
      radiance += blocklightColor;
    }

    interact.scattering += interact.transmittance * radiance;
    interact.transmittance *= stepTransmittance;
  }

  vec3 scatterAlbedo = clamp01(WATER_SCATTERING / WATER_EXCTINCTION);
  interact.scattering *= (1.0 - stepTransmittance) * scatterAlbedo;

  // show(interact.scattering);

  return interact;
}

#endif