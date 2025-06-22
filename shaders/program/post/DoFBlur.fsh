#version 450 core

in vec2 uv;

uniform sampler2D mainDepthTex;
uniform sampler2D DoFCoCTex;
uniform sampler2D sceneTex;

#include "/lib/common.glsl"

const int kernelSampleCount = 22;
const vec2 kernel[kernelSampleCount] = vec2[](
  vec2(0, 0),
  vec2(0.53333336, 0),
  vec2(0.3325279, 0.4169768),
  vec2(-0.11867785, 0.5199616),
  vec2(-0.48051673, 0.2314047),
  vec2(-0.48051673, -0.23140468),
  vec2(-0.11867763, -0.51996166),
  vec2(0.33252785, -0.4169769),
  vec2(1, 0),
  vec2(0.90096885, 0.43388376),
  vec2(0.6234898, 0.7818315),
  vec2(0.22252098, 0.9749279),
  vec2(-0.22252095, 0.9749279),
  vec2(-0.62349, 0.7818314),
  vec2(-0.90096885, 0.43388382),
  vec2(-1, 0),
  vec2(-0.90096885, -0.43388376),
  vec2(-0.6234896, -0.7818316),
  vec2(-0.22252055, -0.974928),
  vec2(0.2225215, -0.9749278),
  vec2(0.6234897, -0.7818316),
  vec2(0.90096885, -0.43388376)
);

// gets the 'most extreme' value
float extremeFilter(sampler2D sourceTexture, vec2 coord){
  vec4 vals = textureGather(DoFCoCTex, coord, 0);

  float extremeVal = vals[0];

  for(int i = 1; i < 3; i++){
    if(abs(vals[i]) > abs(extremeVal)){
      extremeVal = vals[i];
    }
  }

  return extremeVal;
}

layout(location = 0) out vec3 DoF;

void main(){
  float CoC = extremeFilter(DoFCoCTex, uv).r;

  float radius = mix(0.0, 4.0, abs(CoC));

  vec2 sampleRadius = radius / ap.game.screenSize;

  int samples = 0;

  for (int i = 0; i < kernelSampleCount; i++){
    vec2 offset = kernel[i] * sampleRadius;
    vec3 DoFSample = max0(texture(sceneTex, clamp01(uv + offset)).rgb);
    float sampleCoC = extremeFilter(DoFCoCTex, clamp01(uv + offset)).r;

    if(sign(sampleCoC) == sign(CoC)){
      DoF += DoFSample;
      samples++;
    } 
  }

  DoF /=  float(samples);
}