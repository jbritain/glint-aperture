#version 450 core

#include "/lib/common.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 uv;



layout(location = 0) out vec3 color;

void main(){
  color = texture(sceneTex, uv).rgb;

  float opaqueDepth = texture(solidDepthTex, uv).r;
  float translucentDepth = texture(mainDepthTex, uv).r;

  if(translucentDepth == 1.0){
    return;
  }

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  vec3 opaqueViewPos = screenSpaceToViewSpace(vec3(uv, opaqueDepth));
  vec3 translucentViewPos = screenSpaceToViewSpace(vec3(uv, translucentDepth));

  bool isWater = gbufferData.materialMask.isFluid;
  bool inWater = ap.camera.fluid == 1;

  if(!inWater && isWater){
    LightInteraction waterInteraction = waterFog(translucentViewPos, opaqueViewPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }

  if(inWater && !isWater){
    LightInteraction waterInteraction = waterFog(vec3(0.0), opaqueViewPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }
  
  vec4 translucents = texture(translucentsTex, uv);
  color = mix(color, translucents.rgb, translucents.a);

  if(inWater && isWater){
    LightInteraction waterInteraction = waterFog(vec3(0.0), translucentViewPos);
    color.rgb = color.rgb * waterInteraction.transmittance + waterInteraction.scattering;
  }
}