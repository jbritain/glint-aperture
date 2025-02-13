#version 450 core

layout(local_size_x = 4, local_size_y = 4, local_size_z =  4) in;

#include "/lib/common.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap1;
layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap2;
layout (R32UI) uniform uimage3D voxelMap;

vec3 gatherLight(ivec3 voxelPos, uint metadata){
  const ivec3[6] sampleOffsets = ivec3[6](
    ivec3( 0, -1,  0), // DOWN
    ivec3( 0,  1,  0), // UP
    ivec3( 0,  0, -1), // NORTH
    ivec3( 0,  0,  1), // SOUTH
    ivec3(-1,  0,  0), // WEST
    ivec3( 1,  0,  0)  // EAST
  );

  vec3 light = vec3(0.0);


  for(int i = 0; i < 6; i++){
    if(bitfieldExtract(metadata, i, 1) == 1){
      continue;
    }

    ivec3 offsetPos = voxelPos + sampleOffsets[i] + getPreviousVoxelOffset();

    if(EVEN_FRAME){
      light += imageLoad(floodFillVoxelMap1, offsetPos).rgb;
    } else {
      light += imageLoad(floodFillVoxelMap2, offsetPos).rgb;
    }
  }

  light /= 6.0;

  return light;
}

vec3 getEmittedLight(ivec3 voxelPos){
  uint sampleBlockID = imageLoad(voxelMap, voxelPos).r;

  float emission = iris_getEmission(sampleBlockID) / 15.0;
  vec4 lightColor = iris_getLightColor(sampleBlockID);

  return lightColor.rgb * emission * 32.0;
}

void main(){
  ivec3 pos = ivec3(gl_GlobalInvocationID); // position in the voxel map we are working with

  uint blockID = imageLoad(voxelMap, pos).r;
  uint metadata = iris_getMetadata(blockID);

  vec3 emitted = getEmittedLight(pos);
  vec3 indirect = iris_isFullBlock(blockID) ? vec3(0.0) : gatherLight(pos, metadata);

  vec4 lightColor = iris_getLightColor(blockID);

  indirect *= (lightColor.rgb * (lightColor.a) + (1.0 - lightColor.a));
  
  vec3 color = emitted + indirect;

  if(EVEN_FRAME){
    imageStore(floodFillVoxelMap2, pos, vec4(color, 1.0));
  } else {
    imageStore(floodFillVoxelMap1, pos, vec4(color, 1.0));
  }
}