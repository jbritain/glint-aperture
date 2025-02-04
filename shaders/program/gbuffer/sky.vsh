#version 450 core
#extension GL_ARB_shader_viewport_layer_array : require

void iris_emitVertex(inout VertexData data) {
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

out vec2 uv;
out vec4 color;

void iris_sendParameters(VertexData data) {
    color = data.color;
    uv = data.uv;
}