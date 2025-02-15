#version 450 core

in vec2 uv;

#define GBUFFER_SAMPLERS
#define SHADOW_SAMPLERS
#define SKY_SAMPLERS
#define VOXEL_SAMPLERS

#include "/lib/common.glsl"
#include "/lib/lighting/shading.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout(location = 0) out vec4 color;

vec3 hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yxz + 19.19);
    return fract(vec3(p.x * p.y, p.y * p.z, p.z * p.x));
}

void main(){
  float depth = texture(solidDepthTex, uv).r;

  	// show(texture(previousSceneTex, (gl_FragCoord.xy / textureSize(previousSceneTex, 0))));

  if(depth == 1.0){
    color = texture(sceneTex, uv);
    return;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  vec3 worldDir = normalize(feetPlayerPos);

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  vec3 worldNormal = mat3(ap.camera.viewInv) * gbufferData.faceNormal;
  vec3 worldMappedNormal = mat3(ap.camera.viewInv) * gbufferData.mappedNormal;
  vec3 voxelPos = mapVoxelPosInterp(feetPlayerPos - worldNormal * 0.5 + worldMappedNormal);
  vec3 blocklightColor;
  if(EVEN_FRAME){
    blocklightColor = textureLod(floodFillVoxelMapTex2, voxelPos, 0).rgb;
  } else {
    blocklightColor = textureLod(floodFillVoxelMapTex1, voxelPos, 0).rgb;
  }

  // blocklightColor = vec3(0.0);

  vec3 f;
  color.rgb = getShadedColor(gbufferData.material, gbufferData.mappedNormal, gbufferData.faceNormal, gbufferData.lightmap.y, blocklightColor, viewPos, f);
  color.rgb += texture(globalIlluminationTex, uv).rgb * gbufferData.material.albedo;

  // show(blocklightColor);
  // for(int i = 3; i >= 0; i -= 1){
    // show(texture(shadowColorTex, vec3(uv, 3)));
    // show(blocklightColor);
  // }

  // show(texture(cloudSkyLUTTex, mapSphere(normalize(feetPlayerPos))));
  
}