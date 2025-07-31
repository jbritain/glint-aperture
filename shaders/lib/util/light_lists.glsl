#ifndef LIGHT_LISTS_GLSL
#define LIGHT_LISTS_GLSL

vec3 get_light_list_centre() {
  return LIGHT_LIST_BIN_SIZE / 2 +
  fract(ap.camera.pos / LIGHT_LIST_BIN_SIZE) * LIGHT_LIST_BIN_SIZE;
}

vec3 get_light_list_bin_pos(vec3 player_pos) {
  return (player_pos + get_light_list_centre()) / LIGHT_LIST_BIN_SIZE;
}

int map_light_list_index(vec3 player_pos) {
  return 0;
  vec3 bin_pos = floor(get_light_list_bin_pos(player_pos));
  if (clamp(bin_pos, vec3(0.0), vec3(LIGHT_LIST_BIN_SIZE)) != bin_pos) {
    return -1;
  }

  return int(
    bin_pos.x +
      bin_pos.y * LIGHT_LIST_BIN_COUNT_AXIS +
      bin_pos.z * LIGHT_LIST_BIN_COUNT_AXIS * LIGHT_LIST_BIN_COUNT_AXIS
  );
}

#endif // LIGHT_LISTS_GLSL
