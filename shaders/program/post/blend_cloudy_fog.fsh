#version 460 core

in vec2 uv;

uniform sampler2D scene_tex;
uniform sampler2D mainDepthTex;
uniform sampler2D cloudy_fog_tex_w;
uniform sampler3D atmospheric_fog_lut_tex;
uniform sampler2D cloud_shadow_tex;

#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/atmosphere.glsl"

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;
  if (
    ap.camera.pos.y < cumulus_cloud_layer.base_height &&
    ap.camera.fluid == 0
  ) {
    vec4 fog;
    if (depth == 1.0) {
      fog = texture(atmospheric_fog_lut_tex, vec3(uv, depth)); // aerial perspective

      color = fma(color, vec3(fog.a), fog.rgb);
    }

    fog = texture(cloudy_fog_tex_w, uv); // volumetric fog

    color = fma(color, vec3(fog.a), fog.rgb);

  }

}
