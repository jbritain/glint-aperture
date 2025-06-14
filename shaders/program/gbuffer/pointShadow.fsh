#version 450 core

#include "/lib/common.glsl"

in vec2 uv;

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 col = iris_sampleBaseTex(mUV);

  if (iris_discardFragment(col)) discard;
}