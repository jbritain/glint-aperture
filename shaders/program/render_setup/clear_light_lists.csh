#version 460 core

layout(local_size_x = 64) in;

#include "/lib/buffers/light_lists.glsl"

void main() {
  light_lists[uint(gl_GlobalInvocationID.x)].light_count = 0;
  light_lists[uint(gl_GlobalInvocationID.x)].final_light_count = 0;
}
