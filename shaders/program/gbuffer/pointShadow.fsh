#version 450 core

#include "/lib/common.glsl"

in vec2 uv;
in vec3 modelPos;

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 col = iris_sampleBaseTex(mUV);
  float emission = iris_sampleSpecularMap(mUV).a;

  if(emission > 0.1 && emission != 1.0 && maxVec3(modelPos) < 0.6){
    discard;
  } else if(iris_discardFragment(col) && maxVec3(modelPos) >= 0.6){
    discard;
  }
  
}