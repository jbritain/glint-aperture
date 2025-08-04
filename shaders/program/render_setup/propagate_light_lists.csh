#version 460 core

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

#include "/lib/common.glsl"
#include "/lib/buffers/light_lists.glsl"
#include "/lib/misc/light_lists.glsl"

// returns whether our own light list is now full
bool collect_lights(uint sample_bin_index, uint target_bin_index, uvec3 target_bin_pos){
  if(sample_bin_index >= LIGHT_LIST_BIN_COUNT) return false;

  for(int i = 0; i < min(light_lists[sample_bin_index].light_count, MAX_LIGHTS_PER_BIN); i++){
    // check if the light in question can actually populate this bin
    ap_PointLight light = iris_getPointLight(light_lists[sample_bin_index].light_indeces[i]);

    vec3 min_corner = target_bin_pos * LIGHT_LIST_BIN_SIZE - LIGHT_LIST_VOLUME_SIZE / 2.0 - fract(ap.camera.pos);
    vec3 max_corner = min_corner + vec3(LIGHT_LIST_BIN_SIZE);

    float min_distance = min(min_vec3(abs(min_corner - light.pos)), min_vec3(abs(max_corner - light.pos)));
    if(min_distance > LIGHT_RADIUS) continue;

    write_to_light_list_unsafe(target_bin_index, light_lists[sample_bin_index].light_indeces[i]);
  }
  return false;
}

void main(){


  uvec3 bin_pos = uvec3(gl_GlobalInvocationID.xyz);
  int target_bin_index = bin_pos_to_bin_index(bin_pos);
  if(target_bin_index < 0 || target_bin_index >= LIGHT_LIST_BIN_COUNT) return;
  
  const int extra_bins = LIGHT_RADIUS / LIGHT_LIST_BIN_SIZE; // at maximum, this many bins in either direction can contain a light that also affects this bin

  for(int x = -extra_bins; x <= extra_bins; x++){
    for(int y = -extra_bins; y <= extra_bins; y++){
      for(int z = -extra_bins; z <= extra_bins; z++){
        if(x == 0 && y == 0 && z == 0) continue;

        collect_lights(bin_pos_to_bin_index(bin_pos + ivec3(x, y, z)), target_bin_index, bin_pos);
      }
    }
  }
}