#ifndef LIGHT_LISTS_BUFFER_GLSL
#define LIGHT_LISTS_BUFFER_GLSL

struct LightList {
  uint light_count;
  uint[MAX_LIGHTS_PER_BIN] light_indeces;
};

#ifdef LIGHT_LIST_BINDING
layout(std430, binding = LIGHT_LIST_BINDING) buffer light_list_buffer {
  LightList[LIGHT_LIST_BIN_COUNT] light_lists;
};
#endif

#endif // LIGHT_LISTS_BUFFER_GLSL
