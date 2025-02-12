#version 450 core

#include "/lib/common.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 uv;
in vec4 color;
in vec3 normal;
in vec3 playerPos;
flat in uint blockID;
in uint cascade;

layout(location = 0) out vec4 albedo;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outPlayerPos;
layout(location = 3) out uint encodedShadowMask;

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 mColor = color;

  ShadowMask mask;
  mask.water = false;

  vec4 col = iris_sampleBaseTex(mUV) * mColor;

  if (iris_discardFragment(col)) discard;

  albedo = col;

  if(iris_hasFluid(blockID) && color.r < color.b){ // water
    mask.water = true;
  }


  outNormal = normal;
  outPlayerPos = playerPos;
  encodedShadowMask = encodeShadowMask(mask);
}