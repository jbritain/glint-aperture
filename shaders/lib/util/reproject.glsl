#ifndef REPROJECT_GLSL
#define REPROJECT_GLSL

#include "/lib/util/space_conversions.glsl"

vec3 reproject_view_to_previous_frame(vec3 view_pos) {
  vec3 pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;
  pos += ap.camera.pos;
  pos -= ap.temporal.pos;
  return (ap.temporal.view * vec4(pos, 1.0)).xyz;
}

vec3 reproject_screen_to_previous_frame(vec3 screen_pos) {
  vec3 pos = screen_space_to_view_space(screen_pos);
  pos = reproject_view_to_previous_frame(pos);
  return previous_view_space_to_previous_screen_space(pos);
}

#endif // REPROJECT_GLSL
