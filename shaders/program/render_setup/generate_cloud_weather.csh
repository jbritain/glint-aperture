#version 460 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "/lib/common.glsl"
#include "/lib/util/jessie_utils.glsl"
#include "/lib/noise/perlin_noise.glsl"
#include "/lib/noise/worley_noise.glsl"
#include "/lib/noise/curl_noise.glsl"

layout(rgba8) uniform image2D cloud_weather;

void main(){
  float worley = (1.0 - pow2(sample_worley_noise(vec3(gl_GlobalInvocationID.xy, 0.0), 32, 256, 4))) * 2.0 - 1.0;

  imageStore(cloud_weather, ivec2(gl_GlobalInvocationID.xy), vec4(worley, 0.0, 0.0, 1.0));
}