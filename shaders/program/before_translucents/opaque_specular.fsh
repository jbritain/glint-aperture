#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/brdf.glsl"

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D shadow_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

uniform sampler2D sky_irradiance_lut_tex;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec3 V = -normalize(view_pos);
  vec3 F = schlick(material, saturate(dot(material.texture_normal, V)));

  vec3 specular =
    brdf_specular_area(material, light_dir, V, sun_angular_radius) *
    sunlight_color *
    texture(shadow_tex, uv).r;

  vec2 irradiance_uv =
    cartesian_to_spherical(mat3(ap.camera.viewInv) * material.texture_normal) /
    TAU;

  specular +=
    textureLod(sky_irradiance_lut_tex, irradiance_uv, 0).rgb *
    material.lightmap.y *
    material.albedo; // until we get ssr and sky reflections

  if (material.metal_id == NO_METAL) {
    color = mix(color, specular, F);
  } else {
    color = specular * F;
  }
}
