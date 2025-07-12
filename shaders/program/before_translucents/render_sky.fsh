#version 460 core

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/atmospherics/sky.glsl"

in vec2 uv;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 color;

void main() {
  float depth = texture(mainDepthTex, uv).r;
  if (depth != 1.0) {
    return;
  }
  vec3 view_dir = normalize(screen_space_to_view_space(vec3(uv, depth)));

  color = get_sky(mat3(ap.camera.viewInv) * view_dir, true);
}
