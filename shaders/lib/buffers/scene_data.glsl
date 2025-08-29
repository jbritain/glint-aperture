#ifndef SCENE_DATA_GLSL
#define SCENE_DATA_GLSL

#ifdef SCENE_DATA_BINDING
layout(binding = SCENE_DATA_BINDING) buffer scene_data {
  vec3 sunlight_color;
  vec3 skylight_color;
};
#else
  vec3 sunlight_color;
  vec3 skylight_color;
#endif

#endif // SCENE_DATA_GLSL