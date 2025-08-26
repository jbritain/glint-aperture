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
uniform sampler2D ssr_tex_w;
uniform sampler3D atmospheric_fog_lut_tex;

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

  shadow.a /= 255.0;

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec3 V = -normalize(view_pos);
  vec3 world_V = mat3(ap.camera.viewInv) * V;

  vec3 direct_fresnel = schlick(
    material,
    dot(world_V, normalize(world_V + world_light_dir))
  );

  vec4 ssr = texture(ssr_tex_w, uv);

  vec3 indirect_fresnel = schlick(material, ssr.a);

  diffuse =
    brdf_diffuse(material, world_light_dir) *
    sunlight_color *
    shadow.rgb *
    (1.0 - direct_fresnel);

  vec2 irradiance_uv = cartesian_to_spherical(material.texture_normal) / TAU;

  diffuse +=
    material.albedo *
    textureLod(sky_irradiance_lut_tex, irradiance_uv, 0).rgb *
    material.lightmap.y *
    (1.0 - indirect_fresnel);

  diffuse +=
    compute_subsurface_scattering(
      material.albedo,
      material.subsurface_scattering,
      shadow.a,
      -V,
      light_dir
    ) *
    (1.0 - indirect_fresnel);

  vec3 specular =
    brdf_specular_area(material, world_light_dir, world_V, sun_angular_radius) *
    sunlight_color *
    shadow.rgb *
    direct_fresnel;

  if (material.metal_id != NO_METAL) {
    specular *= material.albedo;
  }

  specular += ssr.rgb * indirect_fresnel;

  if (material.metal_id == NO_METAL) {
    shaded_color = diffuse + specular;
  } else {
    shaded_color = specular;
  }

  shaded_color +=
    material.emission * material.albedo * EMISSION_STRENGTH * 20.0;

  // *
  // global_illumination.a;

}
