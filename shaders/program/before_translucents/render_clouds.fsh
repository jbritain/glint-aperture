#version 460 core

uniform sampler2D sky_irradiance_lut_tex;

#include "/lib/common.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/util/reproject.glsl"

uniform sampler2D scene_tex;

uniform sampler2D cloud_tex;

uniform sampler2D mainDepthTex;
uniform sampler2D previousSolidDepthTex;

in vec2 uv;

layout(location = 0) out vec3 color;
layout(location = 1) out vec4 clouds;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  if (depth != 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  clouds = get_clouds(
    ap.camera.pos,
    mat3(ap.camera.viewInv) * normalize(view_pos)
  );

  vec3 previous_screen_pos = previous_view_space_to_previous_screen_space(
    reproject_view_to_previous_frame(view_pos)
  );

  if (saturate(previous_screen_pos.xy) == previous_screen_pos.xy) {
    float previous_depth = texture(
      previousSolidDepthTex,
      previous_screen_pos.xy
    ).r;
    if (previous_depth == 1.0) {
      vec4 previous_clouds = texture(cloud_tex, previous_screen_pos.xy);
      clouds = mix(previous_clouds, clouds, 0.1);
    }
  }

  color = fma(color, vec3(clouds.a), clouds.rgb);

}
