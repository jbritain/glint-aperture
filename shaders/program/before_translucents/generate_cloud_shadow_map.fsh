in vec2 uv;

#include "/lib/common.glsl"
#include "/lib/util/shadow_space.glsl"
#include "/lib/atmospherics/clouds.glsl"

uniform sampler2DArray shadowMap;

void main() {
  vec3 shadow_screen_pos = vec3(uv, texture(shadowMap, vec3(uv, gl_Layer)).r);
}
