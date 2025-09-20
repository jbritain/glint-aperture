#version 460 core

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"

layout(rgba8) uniform image3D cloud_detail;

void main(){
  float worley_1 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 8, 4, 2, 0);
  float worley_2 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 4, 8, 1, 1);
  float worley_3 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 2, 16, 1, 2);

  vec3 high_frequency_noise = vec3(worley_1, worley_2, worley_3);

  float high_frequency_fbm =
    high_frequency_noise.r * 0.625 +
    high_frequency_noise.g * 0.25 +
    high_frequency_noise.b * 0.125;

  imageStore(cloud_detail, ivec3(gl_GlobalInvocationID.xyz), vec4(high_frequency_fbm, vec3(1.0)));
}