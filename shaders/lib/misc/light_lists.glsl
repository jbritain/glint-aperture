#ifndef LIGHT_LISTS_GLSL
#define LIGHT_LISTS_GLSL

#include "/lib/buffers/light_lists.glsl"

void write_to_light_list(uint bin_index, uint light_index){
  if(bin_index >= LIGHT_LIST_BIN_COUNT) return;
  uint index = atomicAdd(light_lists[bin_index].light_count, 1);
  atomicAdd(light_lists[bin_index].final_light_count, 1);
  if(index > MAX_LIGHTS_PER_BIN) return;
  light_lists[bin_index].light_indeces[index] = light_index;
}

// for when we can get away without using atomics
void write_to_light_list_unsafe(uint bin_index, uint light_index){
  if(bin_index >= LIGHT_LIST_BIN_COUNT) return;
  uint index = light_lists[bin_index].final_light_count;
  if(index > MAX_LIGHTS_PER_BIN + 1) return;
  light_lists[bin_index].final_light_count += 1;

  light_lists[bin_index].light_indeces[index] = light_index;
}

ivec3 get_light_list_bin_pos(vec3 player_pos) {
  vec3 bin_pos =
    (player_pos + fract(ap.camera.pos) + LIGHT_LIST_VOLUME_SIZE / 2) /
    LIGHT_LIST_BIN_SIZE;

  return ivec3(bin_pos);
}

int bin_pos_to_bin_index(vec3 bin_pos) {
  if(clamp(bin_pos, vec3(0.0), vec3(LIGHT_LIST_BIN_COUNT_AXIS)) != bin_pos){
    return -1;
  }

  return clamp(
    int(
      bin_pos.x +
        bin_pos.y * LIGHT_LIST_BIN_COUNT_AXIS +
        bin_pos.z * LIGHT_LIST_BIN_COUNT_AXIS * LIGHT_LIST_BIN_COUNT_AXIS
    ),
    0,
    LIGHT_LIST_BIN_COUNT
  );
}

int map_light_list_index(vec3 player_pos) {
  return bin_pos_to_bin_index(get_light_list_bin_pos(player_pos));
}

#endif // LIGHT_LISTS_GLSL
