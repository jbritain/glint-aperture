#version 460 core

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D cloud_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D cloud_tex_w;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  if (depth != 1.0) {
    return;
  }

  vec4 clouds = texture(cloud_tex_w, uv);
  color = fma(color, vec3(clouds.a), clouds.rgb);

}
