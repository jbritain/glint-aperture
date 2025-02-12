#ifndef SHADOW_SPACE_GLSL
#define SHADOW_SPACE_GLSL

vec3 getShadowScreenPos(vec3 feetPlayerPos, vec3 worldNormal, out int cascade){
  vec3 shadowViewNormal = mat3(ap.celestial.view) * worldNormal;

  vec4 shadowViewPos = (ap.celestial.view * vec4(feetPlayerPos, 1.0));
  vec4 shadowClipPos;
  
  for(cascade = 0; cascade < 4; cascade++){
    shadowClipPos = ap.celestial.projection[cascade] * shadowViewPos;

    if(clamp(shadowClipPos.xy, vec2(-0.95), vec2(0.95)) == shadowClipPos.xy) break;
  }

  vec3 shadowClipNormal = mat3(ap.celestial.projection[cascade]) * shadowViewNormal;
  shadowClipPos.xyz += shadowClipNormal * 0.1 * pow(2, cascade);

  return shadowClipPos.xyz * 0.5 + 0.5;
}

vec4 getShadowClipPos(vec3 feetPlayerPos, out int cascade){
  vec4 shadowViewPos = (ap.celestial.view * vec4(feetPlayerPos, 1.0));
  vec4 shadowClipPos;
  
  for(cascade = 0; cascade < 4; cascade++){
    shadowClipPos = ap.celestial.projection[cascade] * shadowViewPos;

    if(clamp(shadowClipPos.xy, vec2(-0.95), vec2(0.95)) == shadowClipPos.xy) break;
  }
  return shadowClipPos;
}

vec3 getShadowScreenPos(vec3 feetPlayerPos, out int cascade){
  vec4 shadowViewPos = (ap.celestial.view * vec4(feetPlayerPos, 1.0));
  vec4 shadowClipPos;
  
  for(cascade = 0; cascade < 4; cascade++){
    shadowClipPos = ap.celestial.projection[cascade] * shadowViewPos;

    if(clamp(shadowClipPos.xy, vec2(-0.95), vec2(0.95)) == shadowClipPos.xy) break;
  }

  return shadowClipPos.xyz * 0.5 + 0.5;
}

#endif // SHADOW_SPACE_GLSL
