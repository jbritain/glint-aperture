#version 450 core

uniform sampler2D sceneTex;
uniform sampler2D translucentsTex;

uniform sampler2D gbufferDataTex1;
uniform sampler2D gbufferDataTex2;

uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

uniform sampler3D floodFillVoxelMapTex1;
uniform sampler3D floodFillVoxelMapTex2;

uniform sampler2D globalIlluminationTex;

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArray shadowMap;
uniform sampler2DArray solidShadowMap;
uniform sampler2DArray shadowColorTex;
uniform usampler2DArray shadowMaskTex;

uniform sampler2D previousDepthTex;
uniform sampler2D previousSceneTex;

uniform sampler2D cloudSkyLUTTex;

#include "/lib/common.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/lighting/shading.glsl"

in vec2 uv;



layout(location = 0) out vec3 color;

void main(){
  color = texture(sceneTex, uv).rgb;

  float opaqueDepth = texture(solidDepthTex, uv).r;
  float translucentDepth = texture(mainDepthTex, uv).r;

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(uv, opaqueDepth));
  vec3 opaquePlayerPos = (ap.camera.viewInv * vec4(opaqueViewPos, 1.0)).xyz;
  vec3 translucentViewPos = screenSpaceToViewSpace(vec3(uv, translucentDepth));
  vec3 translucentPlayerPos = (ap.camera.viewInv * vec4(translucentViewPos, 1.0)).xyz;

  bool isWater = gbufferData.materialMask.isFluid;
  bool inWater = ap.camera.fluid == 1;

  if(translucentDepth == 1.0 && !inWater){
    return;
  }

  // refraction
  // TODO: enable refraction once there is buffer flipping helper (please IMS)
  // if(gbufferData.materialMask.isFluid){
  //   vec3 refractionNormal = gbufferData.faceNormal - gbufferData.mappedNormal;
  //   show(gbufferData.faceNormal);

  //   vec3 refractedDir = normalize(refract(normalize(opaqueViewPos), refractionNormal, !inWater ? rcp(1.33) : 1.33));
  //   vec3 refractedViewPos = translucentViewPos + refractedDir * distance(translucentViewPos, opaqueViewPos);
  //   vec3 refractedPos = viewSpaceToScreenSpace(refractedViewPos);

  //   float refractedDepth = texture(solidDepthTex, refractedPos.xy).r;
  //   refractedViewPos = screenSpaceToViewSpace(vec3(refractedPos.xy, refractedDepth));

  //   if(clamp01(refractedPos.xy) == refractedPos.xy && refractedDepth > translucentDepth){
  //     color = texture(sceneTex, refractedPos.xy).rgb;
  //     opaqueDepth = texture(solidDepthTex, refractedPos.xy).r;
  //     opaqueViewPos = refractedViewPos;
  //   } 
  // }

  if(!inWater && isWater){
    LightInteraction waterInteraction = waterFog(translucentPlayerPos, opaquePlayerPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }

  if(inWater && !isWater){
    LightInteraction waterInteraction = waterFog(vec3(0.0), opaquePlayerPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }
  
  vec4 translucents = texture(translucentsTex, uv);
  color = mix(color, translucents.rgb, translucents.a);

  // render water
  if(gbufferData.materialMask.isFluid){
    overrideMaterials(gbufferData.material, gbufferData.materialMask);

    float scatter;
    vec3 shadow = getShadowing(translucentPlayerPos, gbufferData.faceNormal, gbufferData.lightmap, gbufferData.material, scatter);

    vec3 F;
    vec3 waterColor = cookTorrance(gbufferData.material, gbufferData.mappedNormal, gbufferData.faceNormal, translucentViewPos, shadow, scatter, true, F) * sunlightColor;

    waterColor = getScreenSpaceReflections(F, translucentViewPos, gbufferData.material, gbufferData.mappedNormal, gbufferData.lightmap.y);

    color.rgb = mix(color.rgb, waterColor, F);
  }

  if(inWater && isWater){
    LightInteraction waterInteraction = waterFog(vec3(0.0), translucentPlayerPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }
}