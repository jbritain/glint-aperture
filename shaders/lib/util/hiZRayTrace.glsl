#ifndef SCREEN_SPACE_RAY_TRACE_GLSL
#define SCREEN_SPACE_RAY_TRACE_GLSL

#include "/lib/util/reproject.glsl"

#define MAX_THICKNESS 0.001

const float handDepth = 0.0;//MC_HAND_DEPTH * 0.5 + 0.5;

vec2 getCellCount(bool previousFrame, bool opaqueOnly, int lod){
  if(previousFrame){
    return textureSize(previousDepthTex, lod);
  }
  
  if(opaqueOnly){
    return textureSize(previousDepthTex, lod);
  }

  return textureSize(previousDepthTex, lod);
}

vec2 getCell(vec2 pos, vec2 cellCount){
  return vec2(floor(pos * cellCount));
}

vec3 intersectDepthPlane(vec3 o, vec3 d, float t){
  return o + d * t;
}

vec3 intersectCellBoundary(vec3 o, vec3 d, vec2 cell, vec2 cellCount, vec2 crossStep, vec2 crossOffset){
  vec2 index = cell + crossStep;
  vec2 boundary = index / cellCount;
  boundary += crossOffset;

  vec2 delta = boundary - o.xy;
  delta /= d.xy;
  float t = minVec2(delta);

  vec3 intersect = intersectDepthPlane(o, d, t);

  return intersect;
}

float getDepth(vec2 pos, bool previousFrame, bool opaqueOnly, int lod){
  if(previousFrame){
    int component = 0;
    if(opaqueOnly){
      component = 1;
    }
    return texelFetch(previousDepthTex, ivec2(pos * textureSize(previousDepthTex, lod)), lod)[component];
  }
  
  if(opaqueOnly){
    return texelFetch(solidDepthTex, ivec2(pos * textureSize(previousDepthTex, lod)), lod).r;
  }

  return texelFetch(mainDepthTex, ivec2(pos * textureSize(previousDepthTex, lod)), lod).r;
}

// Hi-Z reflections adapted from
// https://sugulee.wordpress.com/2021/01/19/screen-space-reflections-implementation-and-optimization-part-2-hi-z-tracing-method/
// side note but sugulee please make the code blocks on your website a bit bigger
bool rayIntersects(vec3 viewOrigin, vec3 viewDir, int maxSteps, float jitter, bool refine, out vec3 rayPos, bool previousFrame, bool opaqueOnly){
  const int maxMipLevel = int(floor(log2(maxVec2(ap.game.screenSize))));

  rayPos = viewSpaceToScreenSpace(viewOrigin);
  if(previousFrame){
    rayPos = reprojectScreen(rayPos);
  }

  vec3 rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir) - rayPos;

  vec3 rayLengths = (clamp01(sign(rayDir)) - rayPos) / rayDir;
  float rayLength = minVec3(rayLengths);

  vec2 crossStep = sign(rayDir.xy);
  vec2 crossOffset = crossStep / ap.game.screenSize / 128.0;
  crossStep = clamp01(crossStep);

  float minZ = rayPos.z;
  float maxZ = rayPos.z + rayDir.z * rayLength;
  float deltaZ = (maxZ - minZ);

  vec3 o = rayPos;
  vec3 d = rayDir * rayLength;

  int startLevel = 2;
  int stopLevel = 0;

  vec2 startCellCount = getCellCount(previousFrame, opaqueOnly, startLevel);
  vec2 rayCell = getCell(rayPos.xy, startCellCount);
  rayPos = intersectCellBoundary(o, d, rayCell, startCellCount, crossStep, crossOffset * 64.0);

  int level = startLevel;
  uint i = 0;
  float rayZDir = sign(rayDir.z);
  bool isRayBackward = rayZDir == -1;

  while(level >= stopLevel && rayDir.z * rayZDir <= maxZ * rayZDir && i < maxSteps){
    vec2 cellCount = getCellCount(previousFrame, opaqueOnly, level);
    vec2 oldCellIdx = getCell(rayPos.xy, cellCount);

    float cellMinZ = getDepth((oldCellIdx + 0.5) / cellCount, previousFrame, opaqueOnly, level);
    vec3 tempRay = ((cellMinZ > rayPos.z) && !isRayBackward) ? intersectDepthPlane(o, d, (cellMinZ - minZ) / deltaZ) : rayPos;

    vec2 newCellIdx = getCell(tempRay.xy, cellCount);

    float thickness = level == 0 ? (rayPos.z - cellMinZ) : 0.0;
    bool crossed = (isRayBackward && (cellMinZ > rayPos.z)) || (thickness > MAX_THICKNESS) || (oldCellIdx != newCellIdx);
    rayPos = crossed ? intersectCellBoundary(o, d, oldCellIdx, cellCount, crossStep, crossOffset) : tempRay;
    level = crossed ? min(maxMipLevel, level + 1) : level - 1;

    ++i;
  }

  return (level < stopLevel);

  return false;
}
#endif // SCREEN_SPACE_RAY_TRACE_GLSL
