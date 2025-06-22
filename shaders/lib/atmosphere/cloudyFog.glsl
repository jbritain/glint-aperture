#ifndef VOLUMETRIC_FOG_GLSL
#define VOLUMETRIC_FOG_GLSL

#include "/lib/util/shadowSpace.glsl"
#include "/lib/buffers/sceneData.glsl"
#include "/lib/voxel/voxelMap.glsl"

#define FOG_MARCH_LIMIT ap.camera.far
#define FOG_SUBMARCH_LIMIT 150.0

#define FOG_EXTINCTION vec3(1.0)
#define FOG_SAMPLES 32
#define FOG_SUBSAMPLES 4
#define FOG_DUAL_LOBE_WEIGHT 0.7
#define FOG_G 0.4

#define FOG_LOWER_HEIGHT 63
float FOG_UPPER_HEIGHT = 103.0;

float getFogDensity(vec3 pos){
  float fogFactor = 0.0;
  if(ap.world.time < 2000){
    fogFactor = 1.0 - smoothstep(0, 2000, ap.world.time) * 0.8;
  } else if (ap.world.time > 12000){
    fogFactor = smoothstep(12000, 14000, ap.world.time) * 0.8;
  }
  fogFactor += 0.2;
  
  fogFactor += ap.world.rain * 2.0;
  
  
  float heightFactor = 1.0 - pow2(smoothstep(FOG_LOWER_HEIGHT, FOG_UPPER_HEIGHT, pos.y));

  fogFactor *= 0.005;

  fogFactor *= heightFactor;

  // float distanceFactor = smoothstep(ap.camera.far / 2, far, length(pos.xz - ap.camera.pos.xz));

  // fogFactor = mix(fogFactor, 0.1 * pow2(heightFactor), distanceFactor);

  return fogFactor;// + 0.2;
}

// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateFogLightEnergy(vec3 rayPos, float jitter, float costh){
  vec3 a = rayPos;
  vec3 b = rayPos;

  int cascade;
  vec3 shadowScreenPos = getShadowScreenPos(rayPos - ap.camera.pos, cascade).xyz;
  vec3 sunlight = vec3(texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r);

  if(length(sunlight) < 0.01){
    return vec3(0.0);
  }

  if(!rayPlaneIntersection(rayPos, worldLightDir, FOG_LOWER_HEIGHT, b)){ 
    rayPlaneIntersection(rayPos, worldLightDir, FOG_UPPER_HEIGHT, b);
  }

  if(b == rayPos) return vec3(0.0); // this should never happen


  if(distance(a, b) > FOG_SUBMARCH_LIMIT){
    b = a + normalize(b - a) * FOG_SUBMARCH_LIMIT;
  }

  vec3 increment = (b - a) / FOG_SUBSAMPLES;

  vec3 subRayPos = a;
  float totalDensity = 0;


  subRayPos += increment * jitter;

  for(int i = 0; i < FOG_SUBSAMPLES; i++, subRayPos += increment){
    totalDensity += getFogDensity(subRayPos) * length(increment);
  }

  return max0(multipleScattering(totalDensity, costh, -FOG_G, FOG_G, FOG_EXTINCTION, 1, FOG_DUAL_LOBE_WEIGHT, 0.9, 0.8, 0.1) * clamp01((1.0 - exp(-totalDensity * 2))) * sunlight);
}

LightInteraction getCloudFog(vec3 a, vec3 b, float depth){
  LightInteraction interaction;
  interaction.transmittance = vec3(1.0);
  interaction.scattering = vec3(0.0);

  if(getFogDensity(vec3(0.0, FOG_LOWER_HEIGHT, 0.0)) == 0.0){
    return interaction;
  }

  vec3 worldDir = normalize(b - a);

  float mu = clamp01(dot(worldDir, worldLightDir));

  if(distance(a, b) > FOG_MARCH_LIMIT){ // limit how far we can march
    b = a + normalize(b - a) * FOG_MARCH_LIMIT;
  }
  a += ap.camera.pos;
  b += ap.camera.pos;

  if(depth == 1.0 && worldDir.y > 0.0 && b.y > FOG_UPPER_HEIGHT){
    // we need to shift B towards A so that the y is equal to the upper height
    float distanceAboveFog = abs(b.y - FOG_UPPER_HEIGHT);

    vec3 scaleDir = -worldDir;
    scaleDir /= scaleDir.y; // make the y component 1.0

    b += scaleDir * distanceAboveFog;
  }

  int samples = FOG_SAMPLES;
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  vec3 totalTransmittance = vec3(1.0);
  vec3 lightEnergy = vec3(0.0);

  float jitter = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.time.frames) - 0.5;


  vec3 scatter = vec3(0.0);

  vec3 lastRayPos = vec3(0.0);

  for(int i = 0; i < samples; i++){

    lastRayPos = rayPos;
    float progress = float(i + 1 + jitter) / float(samples);
    rayPos = mix(a, b, exp(10.0 * (progress - 1.0)));

    float pointDensity = getFogDensity(rayPos);
    float density = distance(lastRayPos, rayPos) * pointDensity;

    vec3 transmittance = exp(-density * FOG_EXTINCTION);

    if(density < 1e-6){
      continue;
    }

    float lightJitter = interleavedGradientNoise(floor(gl_FragCoord.xy), i * (samples + 1));

    vec3 lightEnergy = calculateFogLightEnergy(rayPos, lightJitter, mu);
    vec3 radiance = lightEnergy * sunlightColor + skylightColor * ap.camera.brightness.y;

    vec3 voxelPos = mapVoxelPosInterp(rayPos - ap.camera.pos);
    if(clamp01(voxelPos) == voxelPos){
      vec3 blocklightColor = vec3(0.0);
      if(EVEN_FRAME){
        blocklightColor = textureLod(floodFillVoxelMapTex2, voxelPos, 0).rgb;
      } else {
        blocklightColor = textureLod(floodFillVoxelMapTex1, voxelPos, 0).rgb;
      }
      radiance += blocklightColor * isotropicPhase;
    }

    #ifdef SHADOW_POINT_LIGHT
      for(int i = 0; i < 64; i++){
        vec3 plVector = (rayPos - ap.camera.pos) - ap.point.pos[i].xyz;
        float plDist = length(plVector);
        if(plDist > POINT_FAR_PLANE) continue;

        vec3 transmittanceToPL = exp(-pointDensity * plDist * FOG_EXTINCTION);
        if(maxVec3(transmittanceToPL) < 0.1) continue;
        
        const float bias = 0.01;
        float depth = (POINT_FAR_PLANE + POINT_NEAR_PLANE - 2.0 * POINT_NEAR_PLANE * POINT_FAR_PLANE / (maxVec3(abs(plVector)) - bias)) / (POINT_FAR_PLANE - POINT_NEAR_PLANE) * 0.5 + 0.5;
        float shadow = texture(pointLightFiltered, vec4(plVector, i), depth);

        radiance += iris_getLightColor(ap.point.block[i]).rgb * iris_getEmission(ap.point.block[i]) * rcp(plDist) * transmittanceToPL * dualHenyeyGreenstein(-FOG_G, FOG_G, dot(worldDir, -normalize(plVector)), FOG_DUAL_LOBE_WEIGHT) * shadow;
      }
    #endif


    vec3 integScatter = (radiance - radiance * clamp01(transmittance)) / FOG_EXTINCTION;

    scatter += integScatter * totalTransmittance;
    totalTransmittance *= transmittance;


    if(maxVec3(totalTransmittance) < 0.01){
      break;
    }

    
  }
  interaction.transmittance = totalTransmittance;
  interaction.scattering = scatter;

  return interaction;
}

#endif // VOLUMETRIC_FOG_GLSL