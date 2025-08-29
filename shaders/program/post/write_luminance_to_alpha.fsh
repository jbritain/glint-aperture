#version 460 core

in vec2 uv;

uniform sampler2D scene_tex;

#include "/lib/common.glsl"

layout(location = 0) out vec4 color;

void main() {
  color = texture(scene_tex, uv);
  color.a = luminance(color.rgb);

  if (isnan(color.a) || isinf(color.a) || color.a < 0.0) {
    color.a = 0.0;
  }

  color.a *= saturate(1.0 - distance(uv, vec2(0.5)) * 2.0) * 4.0;

}
