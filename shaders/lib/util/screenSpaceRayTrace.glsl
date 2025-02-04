#ifndef SCREEN_SPACE_RAY_TRACE_GLSL
#define SCREEN_SPACE_RAY_TRACE_GLSL

#include "/lib/util/reproject.glsl"

#define BINARY_REFINEMENTS 6
#define BINARY_REDUCTION 0.5

const float handDepth = 0.0;//MC_HAND_DEPTH * 0.5 + 0.5;

float getDepth(vec2 pos, bool previousFrame, bool opaqueOnly){


  if(previousFrame){
    int component = 0;
    if(opaqueOnly){
      component = 1;
    }
    return texelFetch(previousDepthTex, ivec2(pos * ap.game.screenSize), 0)[component];
  }
  
  if(opaqueOnly){
    return texelFetch(solidDepthTex, ivec2(pos * ap.game.screenSize), 0).r;
  }

  return texelFetch(mainDepthTex, ivec2(pos * ap.game.screenSize), 0).r;
}

void binarySearch(inout vec3 rayPos, vec3 rayDir, bool previousFrame, bool opaqueOnly){
  vec3 lastGoodPos = rayPos; // stores the last position we know was inside, in case we accidentally step back out
  for (int i = 0; i < BINARY_REFINEMENTS; i++){
    float depth = getDepth(rayPos.xy, previousFrame, opaqueOnly);
    float intersect = sign(depth - rayPos.z);
    lastGoodPos = intersect == 1.0 ? rayPos : lastGoodPos; // update last good pos if still inside
    
    rayPos += intersect * rayDir; // goes back if we're in geometry and forward if we're not
    rayDir *= BINARY_REDUCTION; // scale down the ray
  }
  rayPos = lastGoodPos;
}

// traces through screen space to find intersection point
// thanks, belmu!!
// https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
bool rayIntersects(vec3 viewOrigin, vec3 viewDir, int maxSteps, float jitter, bool refine, out vec3 rayPos, bool previousFrame, bool opaqueOnly){

  if(viewDir.z > 0.0 && viewDir.z >= -viewOrigin.z){
    return false;
  }

  rayPos = viewSpaceToScreenSpace(viewOrigin);
  if(previousFrame){
    rayPos = reprojectScreen(rayPos);
  }

  vec3 rayDir;
  rayDir = viewSpaceToScreenSpace(viewOrigin + viewDir);
  if(previousFrame){
    rayDir = reprojectScreen(rayDir);
  }
  
  rayDir -= rayPos;
  rayDir = normalize(rayDir);

  vec3 temp = abs(sign(rayDir) - rayPos) / max(abs(rayDir), 0.00001);
  float rayLength = minVec3(temp);
  float stepLength = rayLength * rcp(float(maxSteps));

  vec3 rayStep = rayDir * stepLength;
  rayPos += rayStep * jitter + length(rcp(ap.game.screenSize)) * rayDir;

  float depthLenience = max(abs(rayStep.z) * 3.0, 0.02 / pow2(viewOrigin.z)); // Provided by DrDesten

  bool intersect = false;

  for(int i = 0; i < maxSteps; ++i, rayPos += rayStep){
    if(clamp01(rayPos) != rayPos) return false; // we went offscreen

    float depth = getDepth(rayPos.xy, previousFrame, opaqueOnly); // sample depth at ray position

    if(abs(depthLenience - (rayPos.z - depth)) < depthLenience && rayPos.z > handDepth){
      if (i == 0){
        return false;
      }

      intersect = true;
      break;
    }
  }

  if(refine && intersect){
    binarySearch(rayPos, rayStep, previousFrame, opaqueOnly);
  }

  return intersect;
}
#endif // SCREEN_SPACE_RAY_TRACE_GLSL
