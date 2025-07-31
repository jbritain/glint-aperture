#version 460 core

layout(local_size_x = 64) in;

#include "/lib/common.glsl"
#include "/lib/buffers/light_lists.glsl"
#include "/lib/util/light_lists.glsl"

void write_to_light_list(uint bin_index, uint light_index){
  if(clamp(bin_index, 0u, LIGHT_LIST_BIN_COUNT - 1u) != bin_index) return;
  uint index = atomicAdd(light_lists[bin_index].light_count, 1);
  if(index > MAX_LIGHTS_PER_BIN) return;
  light_lists[bin_index].light_indeces[index] = light_index;
}

void main(){
  ap_PointLight light = iris_getPointLight(uint(gl_GlobalInvocationID.x));

  const int light_radius = 16; // TODO: not hardcode this here

  const int extra_bins = light_radius / LIGHT_LIST_BIN_SIZE;
  // for(int x = -extra_bins; x <= extra_bins; x++){
  //   for(int y = -extra_bins; y <= extra_bins; y++){
  //     for(int z = -extra_bins; z <= extra_bins; z++){
          uint bin_index = map_light_list_index(light.pos);// + vec3(x, y, z) * LIGHT_LIST_BIN_SIZE);


          write_to_light_list(bin_index, uint(gl_GlobalInvocationID.x));
  //     }
  //   }
  // }
}