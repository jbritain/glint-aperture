#version 450 core
#extension GL_ARB_shader_viewport_layer_array : require

#include "/lib/common.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout (R32UI) uniform uimage3D voxelMap;

void iris_emitVertex(inout VertexData data) {
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

out vec2 uv;
out vec3 modelPos;

void iris_sendParameters(VertexData data) {
    uv = data.uv;
    modelPos = data.modelPos.xyz;
}