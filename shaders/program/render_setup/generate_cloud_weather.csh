#version 460 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"

layout(rgba8) uniform image2D cloud_weather;

void main(){
  float worley_1 = max0((1.0 - pow2(sample_worley_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 16, 32, 2, 1))) * 3.0 - 2.0);
  float worley_2 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 16, 32, 2, 2);

  float perlin = sample_perlin_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 64, 8, 2);

  float perlin_worley = sqrt(mix(pow3(perlin), worley_2, 0.3));

  imageStore(cloud_weather, ivec2(gl_GlobalInvocationID.xy), vec4(worley_1, perlin_worley, 0.0, 1.0));
}