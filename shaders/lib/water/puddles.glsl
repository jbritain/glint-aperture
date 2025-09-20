#ifndef PUDDLES_GLSL
#define PUDDLES_GLSL

#include "/lib/noise/perlin_noise.glsl"
#include "/lib/util/dither.glsl"

float overlay_blend(float a, float b) {
  return a < 0.5
    ? 2 * a * b
    : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
}

void apply_puddles(inout Gbuffer gbuffer, float heightmap, vec3 world_pos) {
  vec2 noise_pos = fract(world_pos.xz / 128.0) * 128;
  float noise = sample_perlin_noise(vec3(noise_pos, 0), 4, 32, 3);

  noise = saturate(noise * 1.5);

  // noise -= heightmap * 0.2;

  // darkening around and in puddle
  gbuffer.albedo *= (1.0 - smoothstep(0.7, 0.8, noise)) * 0.5 + 0.5;

  // mix with water material
  gbuffer.specular_map.rg = mix(
    gbuffer.specular_map.rg,
    vec2(1.0, 0.02),
    noise
  );

  // // flatten normal as it gets wetter
  // gbuffer.texture_normal = mix(
  //   gbuffer.texture_normal,
  //   gbuffer.geometry_normal,
  //   sqrt(noise)
  // );

}

#endif // PUDDLES_GLSL
