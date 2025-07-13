#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"

layout(location = 0) out vec4 gbuffer_1;
layout(location = 1) out vec4 gbuffer_2;

in vec2 uv;
in vec4 color;
in vec2 lightmap;

in mat3 tbn_matrix;

void iris_emitFragment() {
  Gbuffer gbuffer;

  vec4 albedo = iris_sampleBaseTex(uv) * color;
  if (iris_discardFragment(albedo)) discard;
  gbuffer.albedo = pow(albedo.rgb, vec3(2.2));

  gbuffer.geometry_normal = tbn_matrix[2];
  gbuffer.texture_normal = tbn_matrix[2];

  gbuffer.lightmap = lightmap;

  encode_gbuffer(gbuffer_1, gbuffer_2, gbuffer);
}
