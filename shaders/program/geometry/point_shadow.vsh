#version 450 core
#include "/lib/common.glsl"

void iris_emitVertex(inout VertexData data) {
  data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

out vec2 uv;
out vec3 model_pos;

void iris_sendParameters(VertexData data) {
  uv = data.uv;
  model_pos = data.modelPos.xyz;
}
