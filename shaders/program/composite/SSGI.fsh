#version 450 core

in vec2 uv;

#define GBUFFER_SAMPLERS
#define SHADOW_SAMPLERS

#include "/lib/common.glsl"
#include "/lib/util/reproject.glsl"
#include "/lib/util/screenSpaceRayTrace.glsl"
#include "/lib/buffers/sceneData.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout(location = 0) out vec3 GI;

#define GI_SAMPLES 32

void main(){
  GI = vec3(0.0);

  float depth = texture(solidDepthTex, uv).r;
  if(depth == 1.0){
    return;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  vec3 worldDir = normalize(feetPlayerPos);

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);
  
  int validSamples;

  for(int i = 0; i < GI_SAMPLES; i++){
    vec3 noise = blueNoise(uv, ap.time.frames * GI_SAMPLES + i).rgb;

    float cosTheta = sqrt(noise.x);
    float sinTheta = sqrt(1.0 - noise.x);

    if(cosTheta == 0.0){
      continue;
    }

    float phi = 2.0 * PI * noise.y;

    vec3 hemisphereDir = vec3(
      cos(phi) * sinTheta,
      sin(phi) * sinTheta,
      cosTheta
    );

    mat3 tbn = frisvadTBN(gbufferData.mappedNormal);
    vec3 sampleDir = tbn * hemisphereDir;

    // sampleDir = reflect(normalize(viewPos), gbufferData.faceNormal);

    vec3 GISamplePos;
    if(rayIntersects(viewPos, sampleDir, 16, noise.z, true, GISamplePos, false, true)){
      GI += texture(previousSceneTex, GISamplePos.xy).rgb;

      // GbufferData sampleGbufferData;
      // decodeGbufferData(texelFetch(gbufferDataTex1, ivec2(GISamplePos.xy * ap.game.screenSize), 0), texelFetch(gbufferDataTex2, ivec2(GISamplePos.xy * ap.game.screenSize), 0), sampleGbufferData);

      // vec3 sampleViewPos = screenSpaceToViewSpace(GISamplePos);
      // vec3 samplePlayerPos = (ap.camera.viewInv * vec4(sampleViewPos, 1.0)).xyz;

      // vec3 sampleColor = sampleGbufferData.material.albedo * sunlightColor * fastDiffuse(samplePlayerPos, sampleGbufferData.faceNormal, sampleGbufferData.lightmap, sampleGbufferData.material);
      // sampleColor += sampleGbufferData.material.albedo * pow3(sampleGbufferData.lightmap.y);

      // sampleColor /= cosTheta / PI;

      // GI += sampleColor;
    }

    validSamples++;
  }

  if(validSamples > 0){
      GI /= float(validSamples);
  }



}