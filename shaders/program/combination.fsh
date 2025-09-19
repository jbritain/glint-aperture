#version 460 core

#include "/lib/common.glsl"
#include "/lib/post/tonemap.glsl"
#include "/lib/buffers/light_lists.glsl"
#include "/lib/misc/light_lists.glsl"
#include "/lib/util/text_rendering.glsl"
#include "/lib/util/shadow_space.glsl"

vec3 apply_range(vec3 color, float min_val, float max_val) {
  return clamp((color - min_val) / (max_val - min_val), 0.0, 1.0);
}

uniform sampler2D scene_tex;
uniform sampler2D bloom_tex;
uniform sampler2D _debug_tex;

layout(location = 0) out vec3 color;

in vec2 uv;

void main() {
  color = texture(scene_tex, uv).rgb;

  vec3 bloom = texture(bloom_tex, uv).rgb;
  color = mix(color, bloom, 0.01);
  color = tonemap(color);

  // beginText(ivec2(gl_FragCoord.xy), ivec2(0, ap.game.screenSize.y));
  // for(int i = 0; i < CASCADES; i++){
  //   printVec3(get_shadow_map_pixel_size(i));
  //   printLine();
  //   printLine();
  // }
  
  // endText(color);

  // // light list occupancy visualiser
  // if (
  //   int(gl_FragCoord.y * MAX_LIGHTS_PER_BIN / ap.game.screenSize.y) <
  //   light_lists[int(
  //     gl_FragCoord.x * LIGHT_LIST_BIN_COUNT / ap.game.screenSize.x
  //   )].light_count
  // ) {
  //   color = vec3(1.0);
  // }

  // color = texture(_debug_tex, uv).rgb;

}
