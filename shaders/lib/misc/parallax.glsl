#ifndef PARALLAX_GLSL
#define PARALLAX_GLSL

#define PARALLAX_DISTANCE 32.0
#define PARALLAX_DISTANCE_CURVE 0.8
#define PARALLAX_HEIGHT 0.25
#define PARALLAX_SAMPLES 32

#include "/lib/voxel/voxelMap.glsl"

float getDepth(vec2 texcoord, vec2 dx, vec2 dy){
  return (1.0 - iris_sampleNormalMapGrad(texcoord, dx, dy).a);
}

vec2 localToAtlas(vec2 texcoord, vec4 textureBounds, vec2 singleTexSize){
  // vec2 localCoord = 1.0 - abs(mod(texcoord, 2.0) - 1.0); // mirror the texture coordinate if it goes out of bounds instead of wrapping it
  vec2 localCoord = mod(texcoord, 1.0); // wrap texture coordinate

  return localCoord * singleTexSize + textureBounds.xy;
}

vec2 atlasToLocal(vec2 texcoord, vec4 textureBounds, vec2 singleTexSize){
  return (texcoord - textureBounds.xy) / singleTexSize;
}

vec2 getParallaxTexcoord(vec2 texcoord, vec3 viewPos, mat3 tbnMatrix, out vec3 previousPos, vec2 dx, vec2 dy, float jitter, vec4 textureBounds, vec2 singleTexSize, vec3 midBlock){
  float distFade = smoothstep(PARALLAX_DISTANCE * PARALLAX_DISTANCE_CURVE, PARALLAX_DISTANCE, length(viewPos));

  if(distFade >= 1.0){
    previousPos = vec3(-1.0);
    return texcoord;
  }

  vec3 playerPosCentred = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz + midBlock * rcp(64);


  vec3 viewDir = normalize(-viewPos) * tbnMatrix;

  float currentDepth = getDepth(texcoord, dx, dy);

  const float layerDepth = rcp(PARALLAX_SAMPLES * (1.0 - distFade)); // depth per layer

  vec3 rayStep = vec3(viewDir.xy * rcp(-viewDir.z) * PARALLAX_HEIGHT * (1.0 - distFade), 1.0) * layerDepth;
  vec3 pos = vec3(atlasToLocal(texcoord, textureBounds, singleTexSize), 0.0);

  float depth = getDepth(texcoord, dx, dy);
  if(depth < rcp(255.0)){
    previousPos = pos;
    return texcoord;
  }

  // pos += rayStep * jitter;

  depth = getDepth(localToAtlas(pos.xy, textureBounds, singleTexSize), dx, dy);

  while(depth - pos.z > rcp(255.0)){
    previousPos = pos;

    // if(mod(pos.xy, 1.0) != pos.xy){ // out of block, maybe;
    //   vec3 blockOffset = vec3(floor(pos.xy), 0.0) * tbnMatrix;

    //   ivec3 voxelPos = mapVoxelPos(playerPosCentred + blockOffset);

    //   if(texelFetch(voxelMapTex, voxelPos, 0).r == 0){
    //     discard;
    //   }
    // }

    depth = getDepth(localToAtlas(pos.xy, textureBounds, singleTexSize), dx, dy);
    pos += rayStep;
  }

  depth = getDepth(localToAtlas(pos.xy, textureBounds, singleTexSize), dx, dy);
  // binary refinement
  for(int i = 0; i < 6; i++){
    rayStep /= 2.0;

    pos += rayStep * float(depth - pos.z > rcp(255.0));
    depth = getDepth(localToAtlas(pos.xy, textureBounds, singleTexSize), dx, dy);

    if (depth - pos.z > rcp(255.0)){
      previousPos = pos;
    }
  }

  return localToAtlas(previousPos.xy, textureBounds, singleTexSize);
}

// float getParallaxShadow(vec3 pos, mat3 tbnMatrix, vec2 dx, vec2 dy, float jitter, vec3 viewPos){
//   float distFade = smoothstep(PARALLAX_DISTANCE * PARALLAX_DISTANCE_CURVE, PARALLAX_DISTANCE, length(viewPos));

//   if(distFade >= 1.0){
//     return 1.0;
//   }

//   float NoL = clamp01(dot(normalize(shadowLightPosition), tbnMatrix[2]));
//   if(NoL < 0.01){
//     return 0.0;
//   }

//   vec3 lightDir = normalize(shadowLightPosition) * tbnMatrix;
//   vec3 rayStep = vec3(lightDir.xy * rcp(lightDir.z) * PARALLAX_HEIGHT, -1.0) * pos.z * rcp(PARALLAX_SHADOW_SAMPLES * (1.0 - distFade));

//   if(getDepth(localToAtlas(pos.xy), dx, dy) < pos.z) return distFade;

//   pos += rayStep * jitter;

//   for(int i = 0; i < PARALLAX_SHADOW_SAMPLES; i++){
//     if(getDepth(localToAtlas(pos.xy), dx, dy) < pos.z) return distFade;
//     pos += rayStep;
//   }

//   return 1.0;
// }

#endif