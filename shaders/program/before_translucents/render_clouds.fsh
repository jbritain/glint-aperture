#version 460 core

uniform sampler2D sky_irradiance_lut_tex;

#include "/lib/common.glsl"
#include "/lib/atmospherics/volumetric_clouds.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/util/reproject.glsl"
#include "/lib/util/misc.glsl"

uniform sampler2D scene_tex;

uniform sampler2D cloud_tex;

uniform sampler2D mainDepthTex;
uniform sampler2D previousSolidDepthTex;

in vec2 uv;

layout(location = 0) out vec4 clouds;

void main() {
  clouds = vec4(0.0, 0.0, 0.0, 1.0);
  float depth = max_vec4(textureGather(mainDepthTex, uv, 0));

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  clouds = get_clouds(ap.camera.pos, player_pos, depth == 1.0, true);

  vec3 previous_screen_pos = previous_view_space_to_previous_screen_space(
    reproject_view_to_previous_frame(view_pos)
  );

  if (saturate(previous_screen_pos.xy) == previous_screen_pos.xy) {
    float previous_depth = texture(
      previousSolidDepthTex,
      previous_screen_pos.xy
    ).r;
    if (previous_depth == 1.0) {
      vec4 previous_clouds = catmull_texture(cloud_tex, previous_screen_pos.xy);
      clouds = mix(
        previous_clouds,
        clouds,
        0.05 + clamp(distance(ap.camera.pos, ap.temporal.pos), 0.0, 0.1)
      );
    }
  }

}
