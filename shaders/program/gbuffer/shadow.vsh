#version 450 core
#extension GL_ARB_shader_viewport_layer_array : require

#include "/lib/common.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout (R32UI) uniform uimage3D voxelMap;

void iris_emitVertex(inout VertexData data) {
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

out vec2 uv;
out vec4 color;
out vec3 normal;
out vec3 playerPos;
flat out uint blockID;

void iris_sendParameters(VertexData data) {
    color = data.color;
    uv = data.uv;
    normal = normalize(mat3(inverse(ap.celestial.view)) * mat3(iris_modelViewMatrix) * data.normal.xyz); // TODO: change this when IMS adds shadow model view inverse
    vec3 shadowViewPos = (inverse(iris_projectionMatrix) * data.clipPos).xyz;
    playerPos = (inverse(ap.celestial.view) * vec4(shadowViewPos, 1.0)).xyz;
    blockID = data.blockId;

    ivec3 voxelPos = mapVoxelPos(playerPos + data.midBlock * rcp(64.0));

    if(isWithinVoxelBounds(voxelPos) && gl_VertexID % 4 == 0){
        imageStore(voxelMap, voxelPos, ivec4(data.blockId, 0, 0, 0));
    }


}