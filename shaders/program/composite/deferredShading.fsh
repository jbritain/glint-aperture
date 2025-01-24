#version 450 core

in vec2 uv;

uniform sampler2D sceneTex;
uniform sampler2D gbufferDataTex1;
uniform sampler2D gbufferDataTex2;
uniform sampler2D solidDepthTex;

uniform sampler2DArray shadowMap;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArray shadowColorTex;

#include "/lib/common.glsl"
#include "/lib/lighting/shading.glsl"

layout(location = 0) out vec4 color;

void main(){
  float depth = texture(solidDepthTex, uv).r;

  if(depth == 1.0){
    color = texture(sceneTex, uv);
    return;
  }

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  vec3 worldDir = normalize(feetPlayerPos);

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  color.rgb = getShadedColor(gbufferData.material, gbufferData.mappedNormal, gbufferData.faceNormal, gbufferData.lightmap, viewPos);
}