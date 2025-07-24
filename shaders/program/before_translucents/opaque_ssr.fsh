#version 460 core

#include "/lib/common.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/buffers/scene_data.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/lighting/screen_space_reflections.glsl"

in vec2 uv;

uniform sampler2D mainDepthTex;

uniform sampler2D diffuse_tex;

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

  ssr = compute_screen_space_reflections(
    view_pos,
    material.roughness,
    mat3(ap.camera.view) * material.texture_normal,
    material.lightmap.y,
    mainDepthTex,
    diffuse_tex
  );
}
