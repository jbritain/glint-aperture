#ifndef CAMERA_DATA_GLSL
#define CAMERA_DATA_GLSL

#ifdef CAMERA_DATA_BINDING
layout(std430, binding = CAMERA_DATA_BINDING) buffer camera_data {
  float auto_exposure;
  float centre_depth_smooth;
};
#endif

#endif // CAMERA_DATA_GLSL
