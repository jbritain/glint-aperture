#version 460 core

layout(local_size_x = 64) in;

#include "/lib/common.glsl"
#include "/lib/buffers/light_lists.glsl"
#include "/lib/misc/light_lists.glsl"

void main(){
  ap_PointLight light = iris_getPointLight(uint(gl_GlobalInvocationID.x));

  if(light.block == -1 || gl_GlobalInvocationID.x >= MAX_LIGHTS){
    return;
  }

  ivec3 bin_pos = get_light_list_bin_pos(light.pos);

  int bin_index = bin_pos_to_bin_index(bin_pos);
  if(bin_index == -1){
    return;
  }
  write_to_light_list(bin_index, uint(gl_GlobalInvocationID.x));
}