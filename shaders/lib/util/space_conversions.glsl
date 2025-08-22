#ifndef SPACE_CONVERSIONS_GLSL
#define SPACE_CONVERSIONS_GLSL

vec3 project_and_divide(vec4 pos, mat4 projection) {
  pos = projection * pos;
  return pos.xyz / pos.w;
}

vec3 screen_space_to_view_space(vec3 screen_pos) {
  vec4 hom_pos = ap.camera.projectionInv * vec4(screen_pos * 2.0 - 1.0, 1.0);
  return hom_pos.xyz / hom_pos.w;
}

float screen_space_to_view_space(float depth) {
  vec4 hom_pos =
    ap.camera.projectionInv * vec4(0.0, 0.0, depth * 2.0 - 1.0, 1.0);
  return hom_pos.z / hom_pos.w;
}

vec3 previous_screen_space_to_previous_view_space(vec3 previous_screen_pos) {
  vec4 hom_pos =
    ap.temporal.projectionInv * vec4(previous_screen_pos * 2.0 - 1.0, 1.0);
  return hom_pos.xyz / hom_pos.w;
}

vec3 view_space_to_screen_space(vec3 view_pos) {
  vec4 clip_pos = ap.camera.projection * vec4(view_pos, 1.0);
  return clip_pos.xyz / clip_pos.w * 0.5 + 0.5;
}

float view_space_to_screen_space(float depth) {
  vec4 clip_pos = ap.camera.projection * vec4(0.0, 0.0, depth, 1.0);
  return clip_pos.z / clip_pos.w * 0.5 + 0.5;
}

vec3 previous_view_space_to_previous_screen_space(vec3 previous_view_pos) {
  vec4 clip_pos = ap.temporal.projection * vec4(previous_view_pos, 1.0);
  return clip_pos.xyz / clip_pos.w * 0.5 + 0.5;
}

#endif
