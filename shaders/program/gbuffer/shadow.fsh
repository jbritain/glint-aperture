#version 450 core

in vec2 uv;
in vec4 color;
in vec3 normal;
in vec3 playerPos;

layout(location = 0) out vec4 albedo;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outPlayerPos;

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 mColor = color;

  vec4 col = iris_sampleBaseTex(mUV) * mColor;

  if (iris_discardFragment(col)) discard;

  albedo = col;
  outNormal = normal;
  outPlayerPos = playerPos;
}