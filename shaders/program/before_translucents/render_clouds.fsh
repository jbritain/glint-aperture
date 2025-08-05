#version 460 core

uniform sampler2D sky_irradiance_lut_tex;

#include "/lib/common.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/util/space_conversions.glsl"

uniform sampler2D scene_tex;

uniform sampler2D mainDepthTex;

in vec2 uv;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  if (depth != 1.0) {
    return;
  }

  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));
  vec4 clouds = get_clouds(
    ap.camera.pos,
    mat3(ap.camera.viewInv) * normalize(view_pos)
  );

  color = fma(color, vec3(clouds.a), clouds.rgb);

  show(texture(cloud_shape_tex, vec3(fract(uv), 0.0)).r);

}
