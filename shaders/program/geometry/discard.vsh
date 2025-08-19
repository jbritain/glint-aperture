#version 460 core

void iris_emitVertex(inout VertexData data) {
  data.clipPos = vec4(-10.0);
}

void iris_sendParameters(VertexData data) {}
