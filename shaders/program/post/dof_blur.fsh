#version 460 core

in vec2 uv;

uniform sampler2D mainDepthTex;
uniform sampler2D dof_coc_tex;
uniform sampler2D scene_tex;

#include "/lib/common.glsl"
#include "/lib/util/dither.glsl"

const int kernel_sample_count = 22;
const vec2 kernel[kernel_sample_count] = vec2[](
  vec2(0, 0),
  vec2(0.53333336, 0),
  vec2(0.3325279, 0.4169768),
  vec2(-0.11867785, 0.5199616),
  vec2(-0.48051673, 0.2314047),
  vec2(-0.48051673, -0.23140468),
  vec2(-0.11867763, -0.51996166),
  vec2(0.33252785, -0.4169769),
  vec2(1, 0),
  vec2(0.90096885, 0.43388376),
  vec2(0.6234898, 0.7818315),
  vec2(0.22252098, 0.9749279),
  vec2(-0.22252095, 0.9749279),
  vec2(-0.62349, 0.7818314),
  vec2(-0.90096885, 0.43388382),
  vec2(-1, 0),
  vec2(-0.90096885, -0.43388376),
  vec2(-0.6234896, -0.7818316),
  vec2(-0.22252055, -0.974928),
  vec2(0.2225215, -0.9749278),
  vec2(0.6234897, -0.7818316),
  vec2(0.90096885, -0.43388376)
);

// gets the 'most extreme' value
float extreme_filter(sampler2D source_texture, vec2 coord) {
  vec4 vals = textureGather(source_texture, coord, 0);

  float extreme_val = vals[0];

  for (int i = 1; i < 3; i++) {
    if (abs(vals[i]) > abs(extreme_val)) {
      extreme_val = vals[i];
    }
  }

  return extreme_val;
}

layout(location = 0) out vec3 dof;

void main() {
  float coc = extreme_filter(dof_coc_tex, uv).r;

  float radius = mix(0.0, 2.0, abs(coc));

  vec2 sample_radius = radius / textureSize(scene_tex, 0).xy;

  int samples = 0;

  float jitter = interleaved_gradient_noise(
    floor(gl_FragCoord.xy),
    ap.time.frames
  );
  float theta = jitter * TAU; // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);
  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);

  for (int i = 0; i < kernel_sample_count; i++) {
    vec2 offset = kernel[i] * sample_radius;
    vec3 dof_sample = max0(textureLod(scene_tex, saturate(uv + offset), 0).rgb);
    float sample_coc = extreme_filter(dof_coc_tex, saturate(uv + offset)).r;

    if (sign(sample_coc) == sign(coc)) {
      dof += dof_sample;
      samples++;
    }
  }

  if (samples == 0) {
    dof = texture(scene_tex, uv).rgb;
  } else {
    dof /= float(samples);
  }

}
