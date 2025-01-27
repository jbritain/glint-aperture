#version 450 core

in vec2 uv;

#include "/lib/common.glsl"
#include "/lib/util/shadowSpace.glsl"

layout(location = 0) out vec3 GI;

// 16 blocks
#define GI_RADIUS 16
#define GI_SAMPLES 16

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
  GI = vec3(0.0);

  if(depth == 1.0){

    return;
  }

  GbufferData gbufferData;
  decodeGbufferData(texture(gbufferDataTex1, uv), texture(gbufferDataTex2, uv), gbufferData);

  vec3 worldNormal = mat3(ap.camera.viewInv) * gbufferData.faceNormal;

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  int cascade;

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.frame.counter);

  mat3 shadowTBN = frisvadTBN(worldLightDir);

  float normalizationFactor = pow2(GI_RADIUS);

  for(int i = 0; i < GI_SAMPLES; i++){
    vec2 offset = weightedVogelDiscSample(i, GI_SAMPLES, jitter);
    vec3 worldOffset = (shadowTBN[0] * offset.x + shadowTBN[1] * offset.y) * GI_RADIUS;
    vec3 samplePlayerPos = feetPlayerPos + worldOffset;

    int cascade;
    vec3 samplePos = getShadowScreenPos(samplePlayerPos, worldNormal, cascade);

    vec3 flux = texture(shadowColorTex, vec3(samplePos.xy, cascade)).rgb;
    vec3 sampleNormal = texture(shadowNormalTex, vec3(samplePos.xy, cascade)).xyz;
    vec3 actualSamplePos = texture(shadowPositionTex, vec3(samplePos.xy, cascade)).xyz;

    flux *= max0(dot(actualSamplePos - samplePlayerPos, sampleNormal));
    flux *= max0(dot(worldNormal, samplePlayerPos - actualSamplePos));
    flux /= max(pow4(distance(actualSamplePos, samplePlayerPos)), 0.01);
    GI += flux;
  }

  GI /= GI_SAMPLES;
  // GI *= normalizationFactor;

}