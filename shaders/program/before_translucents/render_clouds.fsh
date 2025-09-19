#version 460 core

uniform sampler2D sky_irradiance_lut_tex;
uniform sampler2D cloud_shadow_tex;

#include "/lib/common.glsl"
#include "/lib/atmospherics/clouds.glsl"
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

  vec4 cumulus_clouds = get_clouds(
    cumulus_cloud_layer,
    ap.camera.pos,
    player_pos,
    depth == 1.0,
    true
  );

  vec4 stratus_clouds = get_clouds(
    stratus_cloud_layer,
    ap.camera.pos,
    player_pos,
    depth == 1.0,
    true
  );

  if (ap.camera.pos.y < cumulus_cloud_layer.top_height) {
    clouds = stratus_clouds;
    clouds.rgb = fma(clouds.rgb, vec3(cumulus_clouds.a), cumulus_clouds.rgb);
    clouds.a *= cumulus_clouds.a;
  } else {
    clouds = cumulus_clouds;
    clouds.rgb = fma(clouds.rgb, vec3(stratus_clouds.a), stratus_clouds.rgb);
    clouds.a *= stratus_clouds.a;
  }

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
