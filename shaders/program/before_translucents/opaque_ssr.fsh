#version 460 core

uniform sampler2D cloud_spheremap_tex;

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/screen_space_reflections.glsl"
#include "/lib/util/reproject.glsl"

in vec2 uv;

uniform sampler2D mainDepthTex;
uniform sampler2D previousSolidDepthTex;

uniform sampler2D diffuse_tex;
uniform sampler2D ssr_tex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

layout(location = 0) out vec4 ssr;

void main() {
  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  float depth = texture(mainDepthTex, uv).r;

  if (depth == 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  vec3 previous_view_pos = reproject_view_to_previous_frame(view_pos);
  vec3 previous_screen_pos = previous_view_space_to_previous_screen_space(
    previous_view_pos
  );
  previous_screen_pos.z = texture(
    previousSolidDepthTex,
    previous_screen_pos.xy
  ).r;
  vec3 actual_previous_view_pos = previous_screen_space_to_previous_view_space(
    previous_screen_pos
  );

  vec4 previous_ssr = catmull_texture(ssr_tex, previous_screen_pos.xy);

  ssr = compute_screen_space_reflections(
    view_pos,
    material.roughness,
    mat3(ap.camera.view) * material.texture_normal,
    material.lightmap.y,
    mainDepthTex,
    diffuse_tex,
    true
  );

  if (
    distance(previous_view_pos, actual_previous_view_pos) < 0.1 &&
    previous_screen_pos.z != 1.0 &&
    saturate(previous_screen_pos.xy) == previous_screen_pos.xy &&
    material.roughness > 0.01
  )
    ssr.rgb = mix(
      previous_ssr.rgb,
      ssr.rgb,
      0.2 + 0.8 * pow2(material.roughness)
    );

}
