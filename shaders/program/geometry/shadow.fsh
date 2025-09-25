#version 460 core

uniform sampler2D cloud_shadow_tex;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArray shadowMap;

#include "/lib/common.glsl"
#include "/lib/util/shadow_space.glsl"
#include "/lib/water/water_fog.glsl"

layout(location = 0) out vec4 out_color;

uniform sampler2DArray solidShadowMap;

in vec2 uv;
in vec4 color;
flat in uint block_id;
flat in uint cascade;
in vec3 shadow_view_pos;

void iris_emitFragment() {
  out_color = iris_sampleBaseTex(uv) * color;

  if (iris_discardFragment(out_color)) discard;

  if (iris_hasFluid(block_id)) {
    float opaque_depth =
      texture(
        solidShadowMap,
        vec3(gl_FragCoord.xy / textureSize(solidShadowMap, 0).x, cascade)
      ).r *
      get_shadow_map_pixel_size(int(cascade)).z;

    float distance = opaque_depth - shadow_view_pos.z;
    vec3 transmittance = exp(-water_extinction * distance);
    out_color.a = mean3(transmittance);
    out_color.rgb = transmittance;

  }
}
