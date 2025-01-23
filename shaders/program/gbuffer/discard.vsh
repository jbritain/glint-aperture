#version 450 core

void iris_emitVertex(inout VertexData data) {
  data.clipPos = vec4(999);
}

void iris_sendParameters(VertexData data) {}