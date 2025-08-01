#ifndef LIGHT_LISTS_GLSL
#define LIGHT_LISTS_GLSL

ivec3 get_light_list_bin_pos(vec3 player_pos) {
  vec3 bin_pos =
    (player_pos + fract(ap.camera.pos) + LIGHT_LIST_VOLUME_SIZE / 2) /
    LIGHT_LIST_BIN_SIZE;

  bin_pos = clamp(bin_pos, vec3(0.0), vec3(LIGHT_LIST_BIN_COUNT_AXIS - 1));
  return ivec3(floor(bin_pos));
}

int bin_pos_to_bin_index(vec3 bin_pos) {
  return clamp(
    int(
      bin_pos.x +
        bin_pos.y * LIGHT_LIST_BIN_COUNT_AXIS +
        bin_pos.z * LIGHT_LIST_BIN_COUNT_AXIS * LIGHT_LIST_BIN_COUNT_AXIS
    ),
    0,
    LIGHT_LIST_BIN_COUNT - 1
  );
}

int map_light_list_index(vec3 player_pos) {
  return bin_pos_to_bin_index(get_light_list_bin_pos(player_pos));
}

#endif // LIGHT_LISTS_GLSL
