#version 450 core

layout(local_size_x = 4, local_size_y = 4, local_size_z =  4) in;

#include "/lib/common.glsl"
#include "/lib/voxel/voxelMap.glsl"

layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap1;
layout (R11F_G11F_B10F) uniform image3D floodFillVoxelMap2;
layout (RGBA8) uniform image3D voxelMap;

vec3 getColor(ivec3 voxelPos){
  if(EVEN_FRAME){
    return imageLoad(floodFillVoxelMap1, voxelPos).rgb;
  } else {
    return imageLoad(floodFillVoxelMap2, voxelPos).rgb;
  }
}

void main(){
  ivec3 pos = ivec3(gl_GlobalInvocationID); // position in the voxel map we are working with
  ivec3 previousPos = pos - getPreviousVoxelOffset();

  if(imageLoad(voxelMap, pos).r > 0.5){
    vec3 color = vec3(0.0);
    if(EVEN_FRAME){
      imageStore(floodFillVoxelMap2, pos, vec4(color, 1.0));
    } else {
      imageStore(floodFillVoxelMap1, pos, vec4(color, 1.0));
    }
  }

  const ivec3[6] sampleOffsets = ivec3[6](
    ivec3( 1,  0,  0),
    ivec3( 0,  1,  0),
    ivec3( 0,  0,  1),
    ivec3(-1,  0,  0),
    ivec3( 0, -1,  0),
    ivec3( 0,  0, -1)
  );

  vec3 color = vec3(0.0);
    
  for(int i = 0; i < 6; i++){
    ivec3 offsetPos = previousPos + sampleOffsets[i];
    if(isWithinVoxelBounds(offsetPos)){
      color += exp2(getColor(offsetPos));
    }
  }

  color /= 6;
  color *= 0.99;

  color = log2(color);

  if(EVEN_FRAME){
    imageStore(floodFillVoxelMap2, pos, vec4(color, 1.0));
  } else {
    imageStore(floodFillVoxelMap1, pos, vec4(color, 1.0));
  }
}