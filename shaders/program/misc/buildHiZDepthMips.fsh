#version 450

#include "/lib/common.glsl"

in vec2 uv;

layout (location = 0) out float depth;

void main(){
  const ivec2 offsets[4] = ivec2[](
    ivec2(0, 0),
    ivec2(0, 1),
    ivec2(1, 0),
    ivec2(1, 1)
  );

  ivec2 texelCoord = ivec2(uv * textureSize(DEPTH_SAMPLER, MIP_LEVEL - 1));

  float depth0 = texelFetch(DEPTH_SAMPLER, texelCoord, MIP_LEVEL - 1).r;
  float depth1 = texelFetch(DEPTH_SAMPLER, texelCoord + ivec2(0, 1), MIP_LEVEL - 1).r;
  float depth2 = texelFetch(DEPTH_SAMPLER, texelCoord + ivec2(1, 0), MIP_LEVEL - 1).r;
  float depth3 = texelFetch(DEPTH_SAMPLER, texelCoord + ivec2(1, 1), MIP_LEVEL - 1).r;

  depth = min4(depth0, depth1, depth2, depth3);
}