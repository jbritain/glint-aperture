#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"

in vec2 uv;

uniform sampler2D final_color_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

uniform sampler2D sky_irradiance_lut_tex;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 color;

void main() {
  color = texture(final_color_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  color = vec3(0.0);
  color +=
    sunlight_color *
    material.albedo *
    saturate(dot(material.geometry_normal, light_dir)) *
    float(material.lightmap.y > 14.0 / 15);

  vec2 irradiance_uv =
    cartesian_to_spherical(mat3(ap.camera.viewInv) * material.geometry_normal) /
    TAU;

  color +=
    material.albedo *
    texture(sky_irradiance_lut_tex, irradiance_uv).rgb *
    material.lightmap.y;

  // color = texture(
  //   sky_irradiance_lut_tex,
  //   cartesian_to_spherical(mat3(ap.camera.viewInv) * normalize(view_pos)) / TAU
  // ).rgb;

}
