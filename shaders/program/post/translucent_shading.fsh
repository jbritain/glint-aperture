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

in vec2 uv;

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
  color = texture(scene_tex, uv).rgb;

  vec4 translucents = texture(translucent_tex, uv);
  if (translucents.a < 0.01) {
    return;
  }

  float depth = texture(mainDepthTex, uv).r;

  if (depth == 1.0) {
    return;
  }

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  if (material.mask.is_fluid) {
    translucents.a = 0.0;
    material.f0 = 0.02;
    material.roughness = 0.0;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;
  vec3 world_V = -normalize(player_pos);
  vec3 direct_fresnel = schlick(
    material,
    dot(world_V, normalize(world_V + world_light_dir))
  );

  vec4 shadow = texture(shadow_tex, uv);

  vec4 ssr = compute_screen_space_reflections(
    view_pos,
    material.roughness,
    mat3(ap.camera.view) * material.texture_normal,
    material.lightmap.y,
    mainDepthTex,
    diffuse_tex
  );

  vec3 indirect_fresnel = schlick(material, ssr.a);

  vec2 irradiance_uv = cartesian_to_spherical(material.texture_normal) / TAU;
  translucents.rgb +=
    material.albedo *
    textureLod(sky_irradiance_lut_tex, irradiance_uv, 0).rgb *
    material.lightmap.y *
    (1.0 - indirect_fresnel);

  color = mix(color, translucents.rgb, translucents.a);

  color += ssr.rgb * indirect_fresnel;

  color +=
    brdf_specular_area(material, world_light_dir, world_V, sun_angular_radius) *
    sunlight_color *
    shadow.rgb *
    direct_fresnel;

}
