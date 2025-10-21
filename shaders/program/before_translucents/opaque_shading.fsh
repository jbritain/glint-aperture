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
uniform sampler2D global_illumination_tex_w;
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

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec4 global_illumination = texture(global_illumination_tex_w, uv);

  // shadow *= float(material.mask.parallax_shadow);

  vec3 V = -normalize(view_pos);
  vec3 world_V = mat3(ap.camera.viewInv) * V;

  vec3 direct_fresnel = schlick(
    material,
    dot(world_V, normalize(world_V + world_light_dir))
  );

  vec4 ssr = texture(ssr_tex_w, uv);

  vec3 max_col = vec3(0.0);
  vec3 min_col = vec3(999999999.0);
  for (int i = 0; i < 8; i++) {
    vec3 neighbourhood_sample = texelFetch(
      ssr_tex_w,
      ivec2(gl_FragCoord.xy) + neighbourhood_offsets[i],
      0
    ).rgb;
    max_col = max(max_col, neighbourhood_sample);
    min_col = min(min_col, neighbourhood_sample);
  }

  ssr.rgb = clamp(ssr.rgb, min_col, max_col);

  vec3 indirect_fresnel =
    material.roughness <= ROUGH_REFLECTION_THRESHOLD
      ? schlick(
        material,
        dot(
          world_V,
          approximate_rough_normal(
            world_V,
            material.texture_normal,
            material.roughness
          )
        )
      )
      : vec3(0.0);

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
    (material.metal_id == NO_METAL
      ? 1.0 - indirect_fresnel
      : vec3(0.0)) *
    global_illumination.a;

  // if (uv.x > 0.5)
  diffuse +=
    material.albedo *
    global_illumination.rgb *
    (material.metal_id == NO_METAL
      ? 1.0 - indirect_fresnel
      : vec3(0.0));

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

  specular += ssr.rgb * indirect_fresnel;

  shaded_color = diffuse + specular;

  shaded_color +=
    (material.emission + 2e-4) * material.albedo * EMISSION_STRENGTH * 20.0;

  // show(global_illumination.a);

}
