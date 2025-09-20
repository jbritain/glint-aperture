#version 460 core

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D cloud_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D cloud_tex_w;
uniform sampler2D cloud_shadow_tex;

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/atmospherics/clouds.glsl"

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;
  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec3 world_pos =
    (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz + ap.camera.pos;

  if (
    depth != 1.0 &&
    !(ap.camera.pos.y > cumulus_cloud_layer.base_height &&
      world_pos.y < cumulus_cloud_layer.base_height ||
      ap.camera.pos.y < cumulus_cloud_layer.top_height &&
        world_pos.y > cumulus_cloud_layer.top_height)
  )
    return;

  // if (depth != 1.0) {
  //   return;
  // }

  vec4 clouds = catmull_texture(cloud_tex_w, uv);
  color = fma(color, vec3(clouds.a), clouds.rgb);

}
