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
#include "/lib/lighting/brdf.glsl"

layout(location = 0) out vec3 GI;

#define GI_SAMPLES 8

void main(){
  GI = vec3(0.0);



  float depth = texture(solidDepthTex, uv).r;
  if(depth == 1.0){
    return;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  vec3 worldDir = normalize(feetPlayerPos);

  ivec2 texelUV = ivec2(uv * textureSize(sceneTex, 0));

  GbufferData gbufferData;
  decodeGbufferData(texelFetch(gbufferDataTex1, texelUV, 0), texelFetch(gbufferDataTex2, texelUV, 0), gbufferData);
  
  int validSamples;
  vec3 fresnel;

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

    mat3 tbn = frisvadTBN(gbufferData.faceNormal);
    vec3 sampleDir = tbn * hemisphereDir;

    // sampleDir = reflect(normalize(viewPos), gbufferData.faceNormal);



    vec3 GISamplePos;
    if(rayIntersects(viewPos, sampleDir, 8, noise.z, true, GISamplePos, false, true)){
      fresnel += schlick(gbufferData.material, dot(sampleDir, normalize(-viewPos)));
      GI += texture(sceneTex, GISamplePos.xy).rgb;
    }

    validSamples++;
  }

  if(validSamples > 0){
    GI /= float(validSamples);
    fresnel /= float(validSamples);
  }

  GI *= (1.0 - fresnel);

  // vec3 previousScreenPos = reprojectScreen(vec3(uv, depth));
  // if(clamp01(previousScreenPos.xy) == previousScreenPos.xy){
  //   vec3 oldGI = texelFetch(globalIlluminationTex, ivec2(previousScreenPos.xy * textureSize(globalIlluminationTex, 0)), 0).rgb;
  //   GI = mix(GI, oldGI, 0.98);
  // }


}