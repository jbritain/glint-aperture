#version 460 core

out vec2 uv;
out vec3 normal;
out vec4 color;
flat out uint block_id;
flat out uint cascade;
out vec3 shadow_view_pos;

void iris_emitVertex(inout VertexData data) {
  data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

void iris_sendParameters(VertexData data) {
  uv = data.uv;
  normal = iris_normalMatrix * data.normal;
  color = data.color;
  block_id = data.blockId;
  cascade = iris_currentCascade;
  shadow_view_pos = (iris_modelViewMatrix * data.modelPos).xyz;
}
