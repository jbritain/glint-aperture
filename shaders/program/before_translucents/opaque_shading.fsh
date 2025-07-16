#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/subsurface_scattering.glsl"

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D shadow_tex;
uniform sampler2D global_illumination_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

uniform sampler2D sky_irradiance_lut_tex;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec3 shaded_color;
layout(location = 1) out vec3 diffuse;

void main() {
  float depth = texture(mainDepthTex, uv).r;
  if (depth == 1.0) {
    shaded_color = texture(scene_tex, uv).rgb;
    diffuse = vec3(0.0);
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  vec4 shadow = texture(shadow_tex, uv);

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec3 V = -normalize(view_pos);
  vec3 world_V = mat3(ap.camera.viewInv) * V;

  diffuse =
    brdf_diffuse(material, world_light_dir) * sunlight_color * shadow.rgb;

  diffuse += compute_subsurface_scattering(
    material.albedo,
    material.subsurface_scattering,
    shadow.a,
    -V,
    light_dir
  );

  vec4 GI = texture(global_illumination_tex, uv);

  vec3 specular =
    brdf_specular_area(material, world_light_dir, world_V, sun_angular_radius) *
    sunlight_color *
    shadow.rgb;

  vec3 fresnel = schlick(material, dot(material.texture_normal, world_V));

  if (material.metal_id == NO_METAL) {
    shaded_color = mix(diffuse, specular, fresnel);
  } else {
    shaded_color = specular * fresnel;
  }

  // TODO: add indirect specular
  vec2 irradiance_uv =
    cartesian_to_spherical(mat3(ap.camera.viewInv) * material.texture_normal) /
    TAU;

  shaded_color +=
    material.albedo *
    textureLod(sky_irradiance_lut_tex, irradiance_uv, 0).rgb *
    material.lightmap.y *
    GI.a;

}
