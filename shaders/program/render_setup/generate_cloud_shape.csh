#version 460 core

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"
#include "/lib/util/misc.glsl"

layout(r16) uniform image3D cloud_shape;

void main(){
  float worley_1 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 16, 8, 3, 0);
  float worley_2 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 8, 16, 3, 1);
  float worley_3 = 1.0 - sample_worley_noise(vec3(gl_GlobalInvocationID.xyz), 4, 32, 3, 2);

  float also_worley = 1.0 - sample_worley_noise(vec3(128 - gl_GlobalInvocationID.xyz), 16,8, 4, 2);
  float perlin = sample_perlin_noise(vec3(gl_GlobalInvocationID.xyz), 8, 16, 4);

  float perlin_worley = remap(perlin, 0.0, 1.0, also_worley, 1.0);

  vec4 low_frequency_noise = vec4(perlin_worley, worley_1, worley_2, worley_3);

  float low_frequency_fbm = saturate(
    low_frequency_noise.g * 0.625 +
    low_frequency_noise.b * 0.25 +
    low_frequency_noise.a * 0.125
  );

  float density = low_frequency_noise.r;
  density = saturate(remap(density, low_frequency_fbm * 0.7, 1.0, 0.0, 1.0));

  imageStore(cloud_shape, ivec3(gl_GlobalInvocationID.xyz), vec4(density, vec3(1.0)));
}