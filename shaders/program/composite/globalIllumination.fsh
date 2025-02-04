#version 450 core

in vec2 uv;

#include "/lib/common.glsl"
#include "/lib/util/shadowSpace.glsl"
#include "/lib/util/reproject.glsl"

layout(location = 0) out vec3 GI;

// 16 blocks
#define GI_RADIUS 4.0
#define GI_SAMPLES 64

// a vogel disk but with the samples still biased towards the centre
vec2 weightedVogelDiscSample(int stepIndex, int stepCount, float noise) {
  float rotation = noise * 2 * PI;
  const float goldenAngle = 2.4;

  float r = stepIndex/float(stepCount);
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

void main(){
  float depth = texture(solidDepthTex, uv).r;

  vec3 previousScreenPos = reprojectScreen(vec3(uv, depth));
  vec3 previousGI = texelFetch(globalIlluminationTex, ivec2(previousScreenPos.xy * textureSize(globalIlluminationTex, 0)), 0).rgb;

  GI = vec3(0.0);
  return;

  if(depth == 1.0){

    return;
  }

  ivec2 texelCoord = ivec2(uv * textureSize(gbufferDataTex1, 0));

  GbufferData gbufferData;
  decodeGbufferData(texelFetch(gbufferDataTex1, texelCoord, 0), texelFetch(gbufferDataTex2, texelCoord, 0), gbufferData);

  vec3 worldNormal = mat3(ap.camera.viewInv) * gbufferData.faceNormal;

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  vec4 shadowViewPos = (ap.celestial.view * vec4(feetPlayerPos, 1.0));
  vec4 shadowClipPos;

  int cascade;
  float radius;
  for(cascade = 0; cascade < 4; cascade++){
    radius = GI_RADIUS * ap.celestial.projection[cascade][0][0];
    shadowClipPos = ap.celestial.projection[cascade] * shadowViewPos;
    vec2 padding = vec2(1.0 - radius);
    if(clamp(shadowClipPos.xy, -padding, padding) == shadowClipPos.xy){
      break;
    }
    if(cascade == 3){
      return;
    }
  }

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.time.frames);

  float normalizationFactor = 2.0 * pow2(GI_RADIUS);

  for(int i = 0; i < GI_SAMPLES; i++){
    vec2 offset = weightedVogelDiscSample(i, GI_SAMPLES, jitter) * radius;
    vec4 offsetPos = shadowClipPos + vec4(offset, 0.0, 0.0);
    vec3 offsetScreenPos = offsetPos.xyz * 0.5 + 0.5;

    if(texture(shadowMap, vec3(offsetScreenPos.xy, cascade)).r == 1.0){
      continue;
    }


    vec3 flux = texture(shadowColorTex, vec3(offsetScreenPos.xy, cascade)).rgb;
    vec3 sampleNormal = texture(shadowNormalTex, vec3(offsetScreenPos.xy, cascade)).xyz;
    vec3 samplePos = texture(shadowPositionTex, vec3(offsetScreenPos.xy, cascade)).xyz;

    flux *= max(dot(feetPlayerPos - samplePos, sampleNormal), 0.01);
    flux *= max(dot(worldNormal, samplePos - feetPlayerPos), 0.01);
    flux /= pow4(distance(samplePos, feetPlayerPos));
    flux *= pow2(float(i)/GI_SAMPLES);
    GI += flux;
  }

  GI /= GI_SAMPLES;
  GI *= normalizationFactor;



  if(clamp01(previousScreenPos.xy) == previousScreenPos.xy && abs(previousScreenPos.z - texture(previousDepthTex, previousScreenPos.xy).r) < 0.001){
    GI = mix(max0(previousGI), GI, 0.1);
  }
  // show(GI);


}