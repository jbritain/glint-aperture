#version 460 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"
#include "/lib/util/misc.glsl"

layout(rgba8) uniform image2D cloud_weather;

void main(){
  vec2 coord = gl_GlobalInvocationID.xy;// + sample_curl_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 32, 16).xy * 200.0;

  float worley_1 = max0(linearstep(0.6  * ((1.0 - ap.world.rain * 1.5) * 0.3 + 0.7), 1.0, (1.0 - pow2(sample_worley_noise(vec3(coord * vec2(1.0, 1.5), 0.0), 16, 32, 3, 1)))));
  float worley_2 = max0(linearstep(0.6 * (1.0 - ap.world.rain * 1.5), 1.0, (1.0 - pow2(sample_worley_noise(vec3(coord.yx * vec2(1.0, 1.5), 0.0), 32, 16, 3, 1))))) + 0.5 * ap.world.rain;

  float perlin = sample_perlin_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 16, 32, 2);

  float perlin_worley = remap(perlin, 0.0, 1.0, worley_2, 1.0);

  imageStore(cloud_weather, ivec2(gl_GlobalInvocationID.xy), vec4(worley_1, worley_2, 0.0, 1.0));
}