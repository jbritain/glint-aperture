#version 450 core

uniform sampler2D sceneTex;

uniform sampler2D mainDepthTex;

uniform sampler2DArrayShadow shadowMapFiltered;

in vec2 uv;

#include "/lib/common.glsl"
#include "/lib/atmosphere/cloudyFog.glsl"

layout(location = 0) out vec4 color;

void main(){
  color = texture(sceneTex, uv);

  float depth = texture(mainDepthTex, uv).r;

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

  LightInteraction cloudyFog = getCloudFog(vec3(0.0), feetPlayerPos, depth);
  
  color.rgb = color.rgb * cloudyFog.transmittance + cloudyFog.scattering;
}