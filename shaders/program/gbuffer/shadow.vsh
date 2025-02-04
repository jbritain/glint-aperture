#version 450 core
#extension GL_ARB_shader_viewport_layer_array : require

#include "/lib/common.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap1;
layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap2;
layout (RGBA8) uniform image3D voxelMap;

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
    playerPos = ((inverse(ap.celestial.view) * inverse(iris_projectionMatrix) * data.clipPos)).xyz;
    blockID = data.blockId;

    vec3 previousPos = playerPos + (ap.temporal.pos - ap.camera.pos);
    ivec3 previousVoxelPos = mapPreviousVoxelPos(previousPos + data.midBlock * rcp(64.0));
    ivec3 voxelPos = mapVoxelPos(playerPos + data.midBlock * rcp(64.0));

    float emission = iris_getEmission(data.blockId) / 15.0;

    if(isWithinVoxelBounds(voxelPos) && gl_VertexID % 4 == 0){
        if(emission > 0.01){
            vec3 lightColor = iris_getLightColor(data.blockId).rgb * emission;
            lightColor *= 4.0;
            if(EVEN_FRAME){
                imageStore(floodFillVoxelMap1, previousVoxelPos, vec4(lightColor, 1.0));
            } else {
                imageStore(floodFillVoxelMap2, previousVoxelPos, vec4(lightColor, 1.0));
            }
        }

        if(iris_isFullBlock(data.blockId)){
            imageStore(voxelMap, voxelPos, vec4(1.0));
        }

        
    }


}