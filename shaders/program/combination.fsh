#version 460 core

#include "/lib/common.glsl"

uniform sampler2D final_color_tex;

layout(location = 0) out vec4 out_color;

in vec2 uv;

void main() {
  out_color = pow(texture(final_color_tex, uv) * 1e-9, vec4(rcp(2.2)));
}
