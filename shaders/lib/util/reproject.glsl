#ifndef REPROJECT_GLSL
#define REPROJECT_GLSL

vec3 reprojectScreen(vec3 screenPos){
  vec3 viewPos = screenSpaceToViewSpace(screenPos);
  vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  playerPos += ap.camera.pos;
  playerPos -= ap.temporal.pos;
  vec3 previousViewPos = (ap.temporal.view * vec4(playerPos, 1.0)).xyz;
  vec3 previousScreenPos = previousViewSpaceToPreviousScreenSpace(previousViewPos);

  return previousScreenPos;
}

vec3 reprojectView(vec3 viewPos){
  vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
  playerPos += ap.camera.pos;
  playerPos -= ap.temporal.pos;
  vec3 previousViewPos = (ap.temporal.view * vec4(playerPos, 1.0)).xyz;
  return viewPos;
}

#endif