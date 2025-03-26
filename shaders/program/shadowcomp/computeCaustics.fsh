#version 450 core

#define SHADOW_SAMPLERS
#include "/lib/common.glsl"
#include "/lib/water/waveNormals.glsl"

in vec2 uv;

layout(location = 0) out vec4 shadowColor;

vec3 shadowScreenToView(vec3 screenPos){
  vec4 pos = vec4(screenPos * 2.0 - 1.0, 1.0); // NDC
  pos = inverse(ap.celestial.projection[gl_Layer]) * pos; // homogeneous
  return pos.xyz / pos.w; // shadow view
}

vec3 shadowViewToScreen(vec3 viewPos){
  vec4 pos = ap.celestial.projection[gl_Layer] * vec4(viewPos, 1.0); // clip
  pos.xyz /= pos.w;
  return pos.xyz * 0.5 + 0.5;
}

void main(){
  vec3 texcoord = vec3(uv, gl_Layer);

  shadowColor = texture(shadowColorTex, texcoord);

  ShadowMask mask = decodeShadowMask(texture(shadowMaskTex, texcoord).r);

  if(!mask.water) return;

  float zRange = (-2.0 / ap.celestial.projection[gl_Layer][2][2]);

  float translucentShadowDepth = texture(shadowMap, texcoord).r;
  float opaqueShadowDepth = texture(solidShadowMap, texcoord).r;

  float depthDifference = opaqueShadowDepth - translucentShadowDepth;
  float distanceThroughWater = zRange * max0(depthDifference);
  vec3 playerPos = texture(shadowPositionTex, texcoord).xyz;
  
  vec3 oldPos = playerPos + worldLightDir * distanceThroughWater;

  vec3 waveNormal = waveNormal(oldPos.xz + ap.camera.pos.xz, vec3(0.0, 1.0, 0.0), 1.0);
  vec3 refracted = refract(worldLightDir, waveNormal, 1.0/1.33);

  vec3 newPos = playerPos + refracted * distanceThroughWater;

  float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
  float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

  shadowColor.a = clamp01(oldArea / max(newArea, 1e-6));
  if(gl_Layer == 1)
  show(shadowColor.a);

  // float translucentDepth = texture(shadowMap, texcoord).r;

  // vec3 translucentPos = shadowScreenToView(vec3(uv, translucentDepth));
  // vec3 worldPos = texture(shadowPositionTex, texcoord).xyz + ap.camera.pos;
  // vec3 waveNormal = waveNormal(worldPos.xz, vec3(0.0, 1.0, 0.0), 1.0);
  // show(dot(waveNormal, vec3(0.0, 1.0, 0.0)));

  // vec3 rayDir = mat3(ap.celestial.view) * refract(mat3(ap.camera.viewInv) * normalize(-ap.celestial.pos), waveNormal, rcp(1.33));

  // // march in shadow NDC space and then sample in screen space
  // vec3 rayPos = (ap.celestial.projection[gl_Layer] * vec4(translucentPos, 1.0)).xyz;
  // rayDir = mat3(ap.celestial.projection[gl_Layer]) * rayDir;

  // vec3 rayStep = rayDir * (rcp(textureSize(shadowMap, 0).x) / length(rayDir.xy)); // TODO: rearrange this shit because it probably simplifies quite a lot

  // float opaqueDepth;

  // for(int i = 0; i < 8; i++){
  //   opaqueDepth = texture(solidShadowMap, vec3(rayPos.xy * 0.5 + 0.5, gl_Layer)).r;

  //   if(opaqueDepth > rayPos.z * 0.5 + 0.5){
  //     break;
  //   }

  //   rayPos += rayStep;
  // }

  // vec3 opaquePos = (inverse(ap.celestial.projection[gl_Layer]) * vec4(rayPos.xy, opaqueDepth * 2.0 - 1.0, 1.0)).xyz;

  // float oldArea = length(dFdx(translucentPos)) * length(dFdy(translucentPos));
  // float newArea = length(dFdx(opaquePos)) * length(dFdy(opaquePos));

  // shadowColor.a = oldArea / newArea;
}