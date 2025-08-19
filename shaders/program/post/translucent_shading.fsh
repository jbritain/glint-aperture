#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/subsurface_scattering.glsl"
#include "/lib/lighting/screen_space_reflections.glsl"
#include "/lib/water/wave_normals.glsl"

in vec2 uv;

uniform sampler2D solidDepthTex;
uniform sampler2D mainDepthTex;
uniform sampler2D scene_tex;
uniform sampler2D translucent_tex;
uniform sampler2D shadow_tex;
uniform sampler2D diffuse_tex;
uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;
uniform sampler2D sky_irradiance_lut_tex;

layout(location = 0) out vec3 color;

void main() {
  bool in_water = ap.camera.fluid == 1;

  color = texture(scene_tex, uv).rgb;

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  vec4 translucents = texture(translucent_tex, uv);
  if (translucents.a < 0.01 && !material.mask.is_fluid) {
    return;
  }

  float sqrf0 = sqrt(material.f0);
  float ior = (1.0 + sqrf0) / (1.0 - sqrf0);

  if (material.mask.is_fluid) {
    ior = in_water ? rcp(1.33) : 1.33;
  }

  float translucent_depth = texture(mainDepthTex, uv).r;

  if (translucent_depth == 1.0) {
    return;
  }

  vec3 translucent_view_pos = screen_space_to_view_space(
    vec3(uv, translucent_depth)
  );
  vec3 translucent_player_pos = (ap.camera.viewInv *
    vec4(translucent_view_pos, 1.0)).xyz;

  vec3 world_V = -normalize(translucent_player_pos);

  if (material.mask.is_fluid) {
    material.texture_normal = wave_normal(
      translucent_player_pos.xz + ap.camera.pos.xz,
      material.geometry_normal,
      1.0
    );

    if (dot(material.texture_normal, world_V) <= 0.1) {
      material.texture_normal = material.geometry_normal;
    }
    if (in_water) {
      material.texture_normal = -material.texture_normal;
    }
  }

  float opaque_depth = texture(solidDepthTex, uv).r;
  vec3 opaque_view_pos = screen_space_to_view_space(vec3(uv, opaque_depth));
  vec3 opaque_player_pos = (ap.camera.viewInv * vec4(opaque_view_pos, 1.0)).xyz;
  vec3 refraction_normal = in_water
    ? material.texture_normal
    : material.geometry_normal - material.texture_normal;

  vec3 refracted = refract(
    normalize(translucent_player_pos),
    refraction_normal,
    rcp(ior)
  );

  vec3 refracted_pos =
    translucent_player_pos +
    refracted * distance(translucent_player_pos, opaque_player_pos);
  refracted_pos = (ap.camera.view * vec4(refracted_pos, 1.0)).xyz;
  refracted_pos = view_space_to_screen_space(refracted_pos);
  float refracted_depth = texture(solidDepthTex, refracted_pos.xy).r;
  if (
    saturate(refracted_pos.xy) == refracted_pos.xy &&
    refracted_depth > translucent_depth
  ) {
    color = texture(scene_tex, refracted_pos.xy).rgb;
  }

  vec3 direct_fresnel = schlick(
    material,
    dot(world_V, normalize(world_V + world_light_dir))
  );

  vec4 shadow = texture(shadow_tex, uv);

  vec4 ssr = compute_screen_space_reflections(
    translucent_view_pos,
    material.roughness,
    mat3(ap.camera.view) * material.texture_normal,
    material.lightmap.y,
    mainDepthTex,
    diffuse_tex,
    false
  );

  vec3 indirect_fresnel = schlick(material, ssr.a);

  vec2 irradiance_uv = cartesian_to_spherical(material.texture_normal) / TAU;
  translucents.rgb +=
    material.albedo *
    textureLod(sky_irradiance_lut_tex, irradiance_uv, 0).rgb *
    material.lightmap.y *
    (1.0 - indirect_fresnel);

  translucents.rgb +=
    material.albedo *
    material.emission *
    EMISSION_STRENGTH *
    (1.0 - indirect_fresnel);

  color = mix(color, translucents.rgb, translucents.a);

  color += ssr.rgb * indirect_fresnel;

  color +=
    brdf_specular_area(material, world_light_dir, world_V, sun_angular_radius) *
    sunlight_color *
    shadow.rgb *
    direct_fresnel;

}
