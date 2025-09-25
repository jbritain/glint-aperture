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

  noise *= ap.world.rain;
  noise *= saturate(dot(gbuffer.geometry_normal, ap.camera.view[1].xyz));
  noise *= smoothstep(0.8, 1.0, gbuffer.lightmap.y);

  noise = noise * 1.8;

  noise = saturate(noise + (1.0 - heightmap) * 2.0 - 0.2);
  
  float porosity = gbuffer.specular_map.b < 64.0/255.0 ? linearstep(0.0, 63.0/255.0, gbuffer.specular_map.b) : 0.0;
  // if(porosity == 0.0) {
  //   porosity = 1.0 - gbuffer.specular_map.r * gbuffer.specular_map.g;
  // }

  // if porosity is less than 0.5, we make the puddles larger as it approaches zero, but only below 0.5 on the heightmap
  if(porosity < 0.5 && porosity != 0.0){
    noise += float(heightmap < 0.5) * (1.0 - porosity);
  } else if(porosity != 0.0) { // otherwise we make the dark parts wider but the wet parts smaller
    noise = mix(noise, 0.5, porosity);
  }

  // darkening around and in puddle
  gbuffer.albedo *= (1.0 - smoothstep(0.7, 0.8, noise)) * 0.5 + 0.5;

  // mix with water material
  gbuffer.specular_map.rg = mix(
    gbuffer.specular_map.rg,
    vec2(1.0, 0.02),
    noise
  );

  // flatten normal as it gets wetter
  gbuffer.texture_normal = normalize(mix(
    gbuffer.texture_normal,
    gbuffer.geometry_normal,
    noise
  ));

}

#endif // PUDDLES_GLSL
