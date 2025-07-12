#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"

in vec2 uv;

uniform sampler2D final_color_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 color;

void main() {
  color = texture(final_color_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    return;
  }

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  color =
    sunlight_color *
    material.albedo *
    saturate(dot(material.geometry_normal, light_dir));
}
