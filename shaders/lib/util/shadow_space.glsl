#ifndef SHADOW_SPACE_GLSL
#define SHADOW_SPACE_GLSL

vec3 get_shadow_screen_pos(vec3 player_pos, vec3 world_normal, out int cascade){
  vec3 shadow_view_normal = mat3(ap.celestial.view) * world_normal;

  vec4 shadow_view_pos = (ap.celestial.view * vec4(player_pos, 1.0));
  vec4 shadow_clip_pos;
  
  for(cascade = 0; cascade <= CASCADES; cascade++){
    shadow_clip_pos = ap.celestial.projection[cascade] * shadow_view_pos;

    if(clamp(shadow_clip_pos.xy, vec2(-0.95), vec2(0.95)) == shadow_clip_pos.xy) break;
  }

  vec3 shadow_clip_normal = mat3(ap.celestial.projection[cascade]) * shadow_view_normal;
  shadow_clip_pos.xyz += shadow_clip_normal * 0.02 * pow(2, cascade);

  return shadow_clip_pos.xyz * 0.5 + 0.5;
}

vec4 get_shadow_clip_pos(vec3 player_pos, out int cascade){
  vec4 shadow_view_pos = (ap.celestial.view * vec4(player_pos, 1.0));
  vec4 shadow_clip_pos;
  
  for(cascade = 0; cascade < CASCADES; cascade++){
    shadow_clip_pos = ap.celestial.projection[cascade] * shadow_view_pos;
    
    if(clamp(shadow_clip_pos.xy, vec2(-0.95), vec2(0.95)) == shadow_clip_pos.xy) break;
  }
  return shadow_clip_pos;
}

vec3 get_shadow_screen_pos(vec3 player_pos, out int cascade){
  vec4 shadow_view_pos = (ap.celestial.view * vec4(player_pos, 1.0));
  vec4 shadow_clip_pos;
  
  for(cascade = 0; cascade < CASCADES; cascade++){
    shadow_clip_pos = ap.celestial.projection[cascade] * shadow_view_pos;

    if(clamp(shadow_clip_pos.xy, vec2(-0.95), vec2(0.95)) == shadow_clip_pos.xy) break;
  }

  return shadow_clip_pos.xyz * 0.5 + 0.5;
}

vec3 get_shadow_screen_pos_cascade(vec3 player_pos, int cascade){
  vec4 shadow_view_pos = (ap.celestial.view * vec4(player_pos, 1.0));
  vec4 shadow_clip_pos = ap.celestial.projection[cascade] * shadow_view_pos;

  return shadow_clip_pos.xyz * 0.5 + 0.5;
}

vec3 get_shadow_screen_pos_reverse(vec3 player_pos, out int cascade){
  vec4 shadow_view_pos = (ap.celestial.view * vec4(player_pos, 1.0));
  vec4 shadow_clip_pos;
  
  for(cascade = CASCADES - 1; cascade >= 0 ; cascade -= 1){
    shadow_clip_pos = ap.celestial.projection[cascade] * shadow_view_pos;

    if(clamp(shadow_clip_pos.xy, vec2(-0.95), vec2(0.95)) == shadow_clip_pos.xy) break;
  }

  return shadow_clip_pos.xyz * 0.5 + 0.5;
}

// from null
vec3 get_shadow_map_pixel_size(int cascade){
  return 0.5 * abs(vec3(ap.celestial.projection[cascade][0].x, ap.celestial.projection[cascade][1].y, ap.celestial.projection[cascade][2].z));
}

#endif // SHADOW_SPACE_GLSL