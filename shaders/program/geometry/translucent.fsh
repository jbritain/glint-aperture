#version 460 core

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArray shadowMap;

uniform sampler2D sky_irradiance_lut_tex;

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/misc/parallax.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/subsurface_scattering.glsl"
#include "/lib/lighting/shadows.glsl"

layout(location = 0) out vec4 diffuse;
layout(location = 1) out vec4 gbuffer_1;
layout(location = 2) out vec4 gbuffer_2;
layout(location = 3) out vec4 shadow;

in vec2 uv;
in vec4 color;
in vec2 lightmap;
flat in uint block_id;
in vec3 view_pos;

in vec4 texture_bounds;
in vec2 texture_size;
in vec3 mid_block;

in mat3 tbn_matrix;

void iris_emitFragment() {
  Gbuffer gbuffer;

  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  vec2 dx = dFdx(uv);
  vec2 dy = dFdy(uv);
  vec3 parallax_pos;
  vec2 uv = apply_parallax(
    uv,
    view_pos,
    tbn_matrix,
    parallax_pos,
    dx,
    dy,
    texture_bounds,
    texture_size,
    mid_block
  );

  vec4 albedo = iris_sampleBaseTex(uv) * color;
  if (iris_discardFragment(albedo)) discard;
  gbuffer.albedo = pow(albedo.rgb, vec3(2.2));

  gbuffer.geometry_normal = tbn_matrix[2];

  vec4 normal_data = iris_sampleNormalMap(uv);
  vec3 texture_normal = normal_data.xyz * 2.0 - 1.0;
  texture_normal.z = sqrt(1.0 - dot(texture_normal.xy, texture_normal.xy));
  gbuffer.texture_normal = tbn_matrix * texture_normal;
  gbuffer.material_ao = normal_data.z;

  gbuffer.specular_map = iris_sampleSpecularMap(uv);

  gbuffer.material_mask = build_material_mask(block_id);

  gbuffer.lightmap = lightmap;

  encode_gbuffer(gbuffer_1, gbuffer_2, gbuffer);
  Material material;
  material = decode_material_from_gbuffer(gbuffer_1, gbuffer_2); // TODO: absolutely not this

  shadow = compute_shadowing_and_blocker_distance(
    player_pos,
    gbuffer.geometry_normal
  );

  vec3 world_V = -normalize(player_pos);

  vec3 direct_fresnel = schlick(
    material,
    dot(world_V, normalize(world_V + world_light_dir))
  );

  diffuse.a = albedo.a;

  diffuse.rgb =
    brdf_diffuse(material, world_light_dir) *
    sunlight_color *
    shadow.rgb *
    (1.0 - direct_fresnel);

}
