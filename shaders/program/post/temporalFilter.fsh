#version 450 core

in vec2 uv;

#define GBUFFER_SAMPLERS

#include "/lib/common.glsl"

layout(location = 0) out vec4 color;

  const ivec2 neighbourhoodOffsets[8] = ivec2[8](
    ivec2( 1, 1),
    ivec2( 1,-1),
    ivec2(-1, 1),
    ivec2(-1,-1),
    ivec2( 1, 0),
    ivec2( 0, 1),
    ivec2(-1, 0),
    ivec2( 0,-1)
  );



void main(){
  float depth = texture(mainDepthTex, uv).r;
  float opaqueDepth = texture(solidDepthTex, uv).r;

  vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
  vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

  vec3 previousPlayerPos = playerPos + ap.camera.pos - ap.temporal.pos;
  vec3 previousViewPos = (ap.temporal.view * vec4(previousPlayerPos, 1.0)).xyz;
  vec4 previousClipPos = ap.temporal.projection * vec4(previousViewPos, 1.0);
  vec3 previousScreenPos = (previousClipPos.xyz / previousClipPos.w) * 0.5 + 0.5;

  color = texture(sceneTex, uv);

  bool rejectSample = clamp01(previousScreenPos.xy) != previousScreenPos.xy;
  // rejectSample = rejectSample || opaqueDepth != depth;

  vec4 historyColor = texture(previousSceneTex, previousScreenPos.xy);

  vec3 maxCol = vec3(0.0);
  vec3 minCol = vec3(999999999.0); // infeasibly large number

  for(int i = 0; i < 8; i++){
    vec3 neighbourhoodSample = texelFetch(sceneTex, ivec2(gl_FragCoord.xy) + neighbourhoodOffsets[i], 0).rgb;
    maxCol = max(maxCol, neighbourhoodSample);
    minCol = min(minCol, neighbourhoodSample);
  }

  historyColor.rgb = clamp(historyColor.rgb, minCol, maxCol);

  color = mix(color, historyColor, 0.7 * float(!rejectSample));
}