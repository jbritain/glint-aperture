#version 460 core

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D cloudy_fog_tex_w;

#include "/lib/atmospherics/clouds.glsl"

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  vec4 fog = texture(cloudy_fog_tex_w, uv);

  if (ap.camera.pos.y < CLOUD_BASE_HEIGHT) {
    color = fma(color, vec3(fog.a), fog.rgb);
  }

}
