#version 450 core

in vec2 uv;
in vec4 color;

layout(location = 0) out vec4 albedo;

#include "/lib/common.glsl"

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 mColor = color;

  albedo = iris_sampleBaseTex(mUV) * mColor;

  if (iris_discardFragment(albedo)) discard;

  #ifdef SKY_BASIC
  // isolate the stars
  if(!(albedo.r == albedo.g && albedo.g == albedo.b)){
    discard;
  }
  albedo.rgb *= vec3(4.0, 4.0, 5.0) * 0.5;
  #endif

  #ifdef SKY_TEXTURED
  // remove bloom around moon by checking saturation since it's coloured while the moon is greyscale
  vec3 color2 = hsv(albedo.rgb);
  if(color2.g > 0.5){
    discard;
  }
  albedo.rgb *= vec3(2.0, 2.0, 3.0);
  #endif


  albedo.rgb = pow(albedo.rgb, vec3(2.2));
}