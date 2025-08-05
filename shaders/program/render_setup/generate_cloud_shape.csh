#version 460 core

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"

layout(rgba8) uniform image3D cloud_shape;

void main(){
  float worley1 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 32, 4, 3);
  float worley2 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 16, 8, 3);
  float worley3 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 8, 16, 3);
  float perlin = sample_perlin_noise(vec3(gl_GlobalInvocationID.xyz), 32, 4, 4);

  imageStore(cloud_shape, ivec3(gl_GlobalInvocationID.xyz), vec4(perlin, worley1, worley2, worley3));
}