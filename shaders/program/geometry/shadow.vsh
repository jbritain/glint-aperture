#version 460 core

out vec2 uv;
out vec3 normal;
out vec4 color;

void iris_emitVertex(inout VertexData data) {
  data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

void iris_sendParameters(VertexData data) {
  uv = data.uv;
  normal = iris_normalMatrix * data.normal;
  color = data.color;
}
