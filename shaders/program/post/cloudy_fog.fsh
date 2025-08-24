#version 460 core

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"

uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2D sky_irradiance_lut_tex;

uniform sampler3D cloud_shape_tex;

#include "/lib/atmospherics/cloudy_fog.glsl"

uniform sampler2D scene_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

in vec2 uv;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float translucent_depth = texture(mainDepthTex, uv).r;

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

    Volume cloudy_fog = cloudy_fog(
      START_POS + ap.camera.pos,
      END_POS + ap.camera.pos
    );

    color *= cloudy_fog.transmittance;
    color += cloudy_fog.scattering;
  }

}

