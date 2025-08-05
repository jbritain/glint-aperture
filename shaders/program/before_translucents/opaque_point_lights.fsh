#version 460 core

uniform samplerCubeArrayShadow pointLightFiltered;

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/point_lights.glsl"

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D diffuse_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

uniform sampler2D cloud_weather_tex;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 color;
layout(location = 1) out vec3 diffuse;

void main() {
  float depth = texture(mainDepthTex, uv).r;
  color = texture(scene_tex, uv).rgb;
  diffuse = texture(diffuse_tex, uv).rgb;
  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec3 light = sample_all_point_lights(player_pos, material);
  color += light;
  diffuse += light;

  uint point_index = map_light_list_index(player_pos);

}
