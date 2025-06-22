#version 450 core

in vec2 uv;

uniform sampler2D DoFTex;
uniform sampler2D DoFCoCTex;
uniform sampler2D sceneTex;


#include "/lib/common.glsl"

layout(location = 0) out vec4 color;


vec3 tentFilter(sampler2D sourceTexture, vec2 coord){
  vec2 offset = 0.5 / ap.game.screenSize;

  vec3 usample = vec3(0.0);
  usample += texture(sourceTexture, clamp01(coord + offset * vec2(1.0))).rgb;
  usample += texture(sourceTexture, clamp01(coord + offset * vec2(1.0, -1.0))).rgb;
  usample += texture(sourceTexture, clamp01(coord + offset * vec2(-1.0))).rgb;
  usample += texture(sourceTexture, clamp01(coord + offset * vec2(-1.0, 1.0))).rgb;

  usample /= 4.0;

  return usample;
}

void main(){
  vec3 DoF = texture(DoFTex, uv).rgb;
  float CoC = texture(DoFCoCTex, uv).r;
  color = texture(sceneTex, uv);

  float DoFStrength = smoothstep(0.1, 1.0, abs(CoC));
  color.rgb = mix(color.rgb, DoF.rgb, clamp01(DoFStrength));
}