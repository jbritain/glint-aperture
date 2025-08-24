#version 460 core

layout(local_size_x = 1) in;

#include "/lib/common.glsl"
#include "/lib/buffers/camera_data.glsl"

uniform sampler2D scene_tex;

void main() {
  float average_luminance = textureLod(scene_tex, vec2(0.5), floor(log2(max_vec2(textureSize(scene_tex, 0))))).a;
  float centre_depth = texture(scene_tex, vec2(0.5)).r;

  const float day_average_luminance = pow(118.0/255.0, 2.2);
  const float night_average_luminance = pow(33.0/255.0, 2.2);
  const float underground_average_luminance = 1.0;

  float target_average_luminance = mix(night_average_luminance, day_average_luminance, smoothstep(-0.1, 0.1, world_light_dir.y));
  // target_average_luminance = mix(underground_average_luminance, target_average_luminance, ap.camera.brightness.y / 240.0);

  float exposure = target_average_luminance / average_luminance;

  exposure = clamp(exposure, 1e-3, 20);

  auto_exposure = mix(auto_exposure, exposure, saturate(exp2(-100.0 * ap.time.delta)));
}