#version 460 core

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"

uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2D sky_irradiance_lut_tex;

uniform sampler3D cloud_shape_tex;
uniform sampler2D cloudy_fog_tex;

#include "/lib/atmospherics/cloudy_fog.glsl"
#include "/lib/common.glsl"
#include "/lib/util/reproject.glsl"

uniform sampler2D scene_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D previousMainDepthTex;

in vec2 uv;

layout(location = 0) out vec4 fog;

void main() {
  fog = vec4(0.0, 0.0, 0.0, 1.0);

  if (ap.camera.fluid == 0) {
    float depth = texture(mainDepthTex, uv).r;
    vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
    vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

    Volume cloudy_fog = cloudy_fog(ap.camera.pos, player_pos + ap.camera.pos);

    fog.rgb = cloudy_fog.scattering;
    fog.a = sum3(cloudy_fog.transmittance) / 3.0;

    vec3 previous_view_pos = reproject_view_to_previous_frame(view_pos);

    vec3 previous_screen_pos = previous_view_space_to_previous_screen_space(
      previous_view_pos
    );
    previous_screen_pos.z = texture(
      previousMainDepthTex,
      previous_screen_pos.xy
    ).r;
    vec3 actual_previous_view_pos =
      previous_screen_space_to_previous_view_space(previous_screen_pos);

    if (
      saturate(previous_screen_pos.xy) == previous_screen_pos.xy &&
      (distance(previous_view_pos, actual_previous_view_pos) <= 2.0 ||
        depth == 1.0 && previous_screen_pos.z == 1.0)
    ) {
      vec4 previous_fog = texture(cloudy_fog_tex, previous_screen_pos.xy);

      fog = mix(
        previous_fog,
        fog,
        0.05 + 0.15 * step(0.1, distance(ap.camera.pos, ap.temporal.pos))
      );
    }
  }

}

