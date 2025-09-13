#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/misc/parallax.glsl"
#include "/lib/util/dither.glsl"

layout(location = 0) out vec4 gbuffer_1;
layout(location = 1) out vec4 gbuffer_2;

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
  gbuffer.albedo = pow(albedo.rgb, vec3(GAMMA));

  gbuffer.geometry_normal = tbn_matrix[2];

  vec4 normal_data = iris_sampleNormalMap(uv);
  vec3 texture_normal = normal_data.xyz * 2.0 - 1.0;
  texture_normal.z = sqrt(1.0 - dot(texture_normal.xy, texture_normal.xy));
  gbuffer.texture_normal = tbn_matrix * texture_normal;
  gbuffer.material_ao = normal_data.z;

  gbuffer.specular_map = iris_sampleSpecularMap(uv);

  // TODO: abstract this out into a function
  if (iris_hasTag(block_id, TAG_LEAVES)) {
    gbuffer.specular_map.b = 1.0;
  }

  gbuffer.material_mask = build_material_mask(block_id);
  gbuffer.material_mask.is_fluid = false;

  gbuffer.material_mask.parallax_shadow =
    step(
      0.01,
      parallax_shadow(
        parallax_pos,
        view_pos,
        tbn_matrix,
        dx,
        dy,
        interleaved_gradient_noise(floor(gl_FragCoord.xy), ap.time.frames)
      )
    ) ==
    1.0;

  gbuffer.lightmap = pow3(lightmap);

  encode_gbuffer(gbuffer_1, gbuffer_2, gbuffer);
}
