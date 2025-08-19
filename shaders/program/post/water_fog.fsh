#version 460 core

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"

uniform sampler2DArray shadowMap;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2D sky_irradiance_lut_tex;

#include "/lib/water/water_fog.glsl"

uniform sampler2D scene_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

uniform sampler2D gbuffer_tex_1;
uniform sampler2D gbuffer_tex_2;

in vec2 uv;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float translucent_depth = texture(mainDepthTex, uv).r;
  if (translucent_depth == 1.0) {
    return;
  }

  Material material = decode_material_from_gbuffer(
    texture(gbuffer_tex_1, uv),
    texture(gbuffer_tex_2, uv)
  );

  bool is_water = material.mask.is_fluid;
  bool in_water = ap.camera.fluid == 1;

  if (CONDITION) {
    vec3 translucent_view_pos = screen_space_to_view_space(
      vec3(uv, translucent_depth)
    );
    vec3 translucent_player_pos = (ap.camera.viewInv *
      vec4(translucent_view_pos, 1.0)).xyz;

    float opaque_depth = texture(solidDepthTex, uv).r;
    vec3 opaque_view_pos = screen_space_to_view_space(vec3(uv, opaque_depth));
    vec3 opaque_player_pos = (ap.camera.viewInv *
      vec4(opaque_view_pos, 1.0)).xyz;

    Volume water_fog = water_fog(START_POS, END_POS);

    color *= water_fog.transmittance;
    color += water_fog.scattering;
  }

}

