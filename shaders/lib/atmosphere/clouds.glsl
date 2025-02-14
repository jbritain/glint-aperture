#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"

// one 2D slice is a 128 by 128 image
#define CLOUD_SHAPE_TILE_SIZE 128
#define CLOUD_EROSION_TILE_SIZE 32

vec4 cloudShapeNoiseSample(vec3 texcoord){
  vec3 texelcoord = vec3(mod(texcoord, 1.0) * CLOUD_SHAPE_TILE_SIZE);

  return texture(cloudShapeNoiseTex, texelcoord.xyz / CLOUD_SHAPE_TILE_SIZE);
}

vec4 cloudErosionNoiseSample(vec3 texcoord){
  vec3 texelcoord = vec3(mod(texcoord, 1.0) * CLOUD_EROSION_TILE_SIZE);

  return texture(cloudErosionNoiseTex, texelcoord.xyz / CLOUD_EROSION_TILE_SIZE);
}

float CUMULUS_DENSITY = 0.03;//mix(0.05, 0.2, wetness);
float CUMULUS_COVERAGE = 0.12;//mix(0.07, 0.21, wetness * 0.5 + thunderStrength * 0.25);
#define CUMULUS_LOWER_HEIGHT 500.0
#define CUMULUS_UPPER_HEIGHT 700.0
#define CUMULUS_SAMPLES 15
#define CUMULUS_SUBSAMPLES 6

#define ALTOCUMULUS_LOWER_HEIGHT 1500.0
#define ALTOCUMULUS_UPPER_HEIGHT 1700.0
#define ALTOCUMULUS_DENSITY 0.02
float ALTOCUMULUS_COVERAGE = 0.08;//mix(0.08, 0.17, wetness * 0.5 + thunderStrength * 0.25);
#define ALTOCUMULUS_SAMPLES 6
#define ALTOCUMULUS_SUBSAMPLES 4

#define CIRRUS_DENSITY 0.001
#define CIRRUS_COVERAGE 0.1
#define CIRRUS_LOWER_HEIGHT 1900.0
#define CIRRUS_UPPER_HEIGHT 2100.0
#define CIRRUS_SAMPLES 1
#define CIRRUS_SUBSAMPLES 1

#define CLOUD_SHAPE_SCALE 2342
#define CLOUD_SHAPE_SCALE_2 7573
#define CLOUD_EROSION_SCALE 234.426

#define CLOUD_DISTANCE 100000.0

// blocks per second
#define CLOUD_SHAPE_SPEED 0.001
#define CLOUD_EROSION_SPEED 0.005

#define CLOUD_EXTINCTION_COLOR vec3(1.0)
#define CLOUD_DUAL_LOBE_WEIGHT 0.7
#define CLOUD_G 0.6

#define CUMULUS_CLOUDS
// #define ALTOCUMULUS_CLOUDS
// #define CIRRUS_CLOUDS

float getCloudDensity(vec3 pos){

  // pos.y = distance(pos, earthCentre) - earthRadius;

  float coverage = 0;
  float densityFactor = 0;
  float heightDenseFactor = 1.0;

  float heightInPlane = 0.0;

  #ifdef CUMULUS_CLOUDS
  if(pos.y >= CUMULUS_LOWER_HEIGHT && pos.y <= CUMULUS_UPPER_HEIGHT){
    coverage = mix(CUMULUS_COVERAGE, 1.0, smoothstep(0.0, 50000.0, 0.0));
    densityFactor = CUMULUS_DENSITY;

    float cumulusCentreHeight = mix(CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, 0.1); // widest part of our cumulus clouds

    if(pos.y <= cumulusCentreHeight){
      heightDenseFactor = sqrt(smoothstep(CUMULUS_LOWER_HEIGHT, cumulusCentreHeight, pos.y));
    } else {
      heightDenseFactor = 1.0 - pow2(smoothstep(cumulusCentreHeight, CUMULUS_UPPER_HEIGHT, pos.y));
    }

    heightInPlane = smoothstep(CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, pos.y);

  } else 
  #endif
  #ifdef ALTOCUMULUS_CLOUDS
  if(pos.y >= ALTOCUMULUS_LOWER_HEIGHT && pos.y <= ALTOCUMULUS_UPPER_HEIGHT){
    coverage = ALTOCUMULUS_COVERAGE;
    densityFactor = ALTOCUMULUS_DENSITY;

    float cumulusCentreHeight = mix(ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, 0.3); // widest part of our cumulus clouds

    if(pos.y <= cumulusCentreHeight){
      heightDenseFactor = smoothstep(ALTOCUMULUS_LOWER_HEIGHT, cumulusCentreHeight, pos.y);
    } else {
      heightDenseFactor = 1.0 - smoothstep(cumulusCentreHeight, ALTOCUMULUS_UPPER_HEIGHT, pos.y);
    }

    heightInPlane = smoothstep(ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, pos.y);

  } else
  #endif
  #ifdef CIRRUS_CLOUDS
   if (pos.y >= CIRRUS_LOWER_HEIGHT && pos.y <= CIRRUS_UPPER_HEIGHT){
    coverage = CIRRUS_COVERAGE;
    densityFactor = CIRRUS_DENSITY;
    pos.x /= 4;
  } else
  #endif
  {
    return 0;
  }


  float shapeDensity2 = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE + vec3(CLOUD_SHAPE_SPEED * ap.time.elapsed, 0.0, 0.0)).r;
  float shapeDensity = cloudShapeNoiseSample(pos / CLOUD_SHAPE_SCALE_2 + vec3(CLOUD_SHAPE_SPEED * ap.time.elapsed, 0.0, 0.0)).r;
  
  
  // erosionDensity = mix(1.0 - erosionDensity, erosionDensity, heightInPlane * 0.5 + 0.5);
  // coverage = mix(coverage * 0.5, coverage * 2.0, texture(noisetex, mod(pos.xz / 100000.0, 1.0)).r);

  float density = clamp01(shapeDensity - (1.0 - coverage));
  density = mix(density, clamp01(shapeDensity2 - (1.0 - coverage) - 0.05), 0.3);
  density *= 10;
  // density *= 1.0 + thunderStrength;

  if(density < 0.01){
    return 0.0;
  }

  float erosionDensity = cloudErosionNoiseSample(pos / CLOUD_EROSION_SCALE  + vec3(CLOUD_EROSION_SPEED * ap.time.elapsed, 0.0, 0.0)).r;

  // erosionDensity = mix(1.0 - erosionDensity, erosionDensity, smoothstep(0.4, 0.6, 1.0 - heightInPlane));

  density -= clamp01(erosionDensity - 0.6);

  density = mix(density, 0.0, pow4(sin(PI * (1.0 - heightDenseFactor) / 2)));

  return max0(density * densityFactor);
}

float getTotalDensityTowardsLight(vec3 rayPos, float jitter, float lowerHeight, float upperHeight, int samples){
  vec3 a = rayPos;
  vec3 b = rayPos;

  samples = int(mix(float(samples), samples * 2.0, 1.0 - abs(worldLightDir.y)));

  bool goingDown = worldLightDir.y < 0;
  bool belowLayer = rayPos.y < lowerHeight;
  if(goingDown != belowLayer) return 0.0;

  if(!rayPlaneIntersection(rayPos, worldLightDir, lowerHeight, b)){ 
    rayPlaneIntersection(rayPos, worldLightDir, upperHeight, b);
  }

  vec3 increment = (b - a) / float(samples);

  vec3 subRayPos = a;
  float totalDensity = 0.0;

  subRayPos += increment * jitter;

  for(int i = 0; i < samples; i++, subRayPos += increment){
    totalDensity += getCloudDensity(subRayPos) * length(increment);
  }

  return totalDensity;
}

// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateCloudLightEnergy(vec3 rayPos, float jitter, float costh, int samples){
  float totalDensity = 0.0;
  #ifdef CUMULUS_CLOUDS
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, samples);
  #endif
  #ifdef ALTOCUMULUS_CLOUDS
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, samples);
  #endif
  #ifdef CIRRUS_CLOUDS
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, samples);
  #endif

  vec3 powder = clamp01((1.0 - exp(-totalDensity * 2 * CLOUD_EXTINCTION_COLOR)));

  return multipleScattering(totalDensity, costh, 0.9, -0.4, CLOUD_EXTINCTION_COLOR, 4, 0.85, 0.9, 0.8, 0.1) * mix(2.0 * powder, vec3(1.0), costh * 0.5 + 0.5);
}

vec3 marchCloudLayer(vec3 playerPos, float depth, vec3 sunlightColor, vec3 skylightColor, inout vec3 totalTransmittance, float lowerHeight, float upperHeight, int samples, int subsamples){
  vec3 worldDir = normalize(playerPos);

  // prevent clouds rendering behind planet (technically wrong but does the job)
  if(depth == 1.0){
    if(worldDir.y < 0.0 && ap.camera.pos.y < lowerHeight){ // below cloud, looking down
      vec3 p;
      if(rayPlaneIntersection(ap.camera.pos, worldDir, 0.0, p)){
        return vec3(0.0);
      }
    }
  }

  #ifdef HIGH_CLOUD_SAMPLES
  samples *= 2;
  #else
  samples = int(ceil(mix(samples * 0.75, float(samples), worldDir.y)));
  #endif

  // we trace from a to b
  vec3 a;
  vec3 b;

  if(!rayPlaneIntersection(ap.camera.pos, worldDir, lowerHeight, a)){
    a = ap.camera.pos;
  }
  if(!rayPlaneIntersection(ap.camera.pos, worldDir, upperHeight, b)){
    b = ap.camera.pos;
  }

  worldDir = normalize(a - b);

  a -= ap.camera.pos;
  b -= ap.camera.pos;

  float mu = dot(worldDir, worldLightDir);

  if(length(a) > length(b)){ // for convenience, a will always be closer to the camera
    vec3 swap = a;
    a = b;
    b = swap;
  }

  if(length(playerPos) < length(b) && depth != 1.0){ // terrain in the way
    b = playerPos;

    if(b.y + ap.camera.pos.y < lowerHeight){ // neither the camera nor the terrain is in the cloud plane
      return vec3(0.0);
    }
  }

  a += ap.camera.pos;
  b += ap.camera.pos;
  
  vec3 rayPos = a;
  vec3 increment = (b - a) / samples;

  vec3 lightEnergy = vec3(0.0);

  #ifdef HIGH_CLOUD_SAMPLES
  float jitter = blueNoise(uv).r;
  #else
  float jitter = blueNoise(uv, ap.time.frames).r;
  #endif
  rayPos += increment * jitter;

  vec3 scatter = vec3(0.0);

  for(int i = 0; i < samples; i++, rayPos += increment){

    float pointDensity = getCloudDensity(rayPos);
    float density = pointDensity * length(increment);
    density = mix(density, 0.0, smoothstep(CLOUD_DISTANCE * 0.8, CLOUD_DISTANCE, length(rayPos.xz - ap.camera.pos.xz)));

    if(density < 1e-6){
      continue;
    }

    vec3 transmittance = exp(-density * CLOUD_EXTINCTION_COLOR);

    #ifdef HIGH_CLOUD_SAMPLES
    float lightJitter = blueNoise(uv, i).r;
    #else
    float lightJitter = blueNoise(uv, i + ap.time.frames * samples).r;
    #endif

    vec3 lightEnergy = calculateCloudLightEnergy(rayPos, lightJitter, mu, subsamples);
    vec3 radiance = lightEnergy * sunlightColor + skylightColor * henyeyGreenstein(0.0, 0.0);

    // if(lightningBoltPosition != vec4(0.0)){
    //   vec3 worldLightningPos = lightningBoltPosition.xyz + ap.camera.pos;
    //   worldLightningPos.y = rayPos.y; // lightning is a column

    //   float lightningDistance = distance(rayPos, worldLightningPos);
    //   float potentialEnergy = pow(1.0 - clamp01(lightningDistance / 1000.0), 12.0);
    //   float pseudoAttenuation = (1.0 - clamp01(pointDensity * 5.0));
    //   radiance += pseudoAttenuation * potentialEnergy * vec3(1.0, 1.0, 2.0);
    // }

    vec3 integScatter = (radiance - radiance * clamp01(transmittance)) / CLOUD_EXTINCTION_COLOR;

    // scatter += getAtmosphericFog(vec4(integScatter, 1.0), rayPos - ap.camera.pos).rgb * totalTransmittance;
    
    scatter += integScatter * totalTransmittance;

    totalTransmittance *= transmittance;

    if(maxVec3(totalTransmittance) < 0.01){
      break;
    }
  }

  return scatter;
}


LightInteraction getClouds(vec3 playerPos, float depth){
  vec3 transmit = vec3(1.0);
  vec3 scatter = vec3(0.0);
  #ifdef VANILLA_CLOUDS
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skylightColor, transmit, VANILLA_CLOUD_LOWER_HEIGHT, VANILLA_CLOUD_UPPER_HEIGHT, VANILLA_CLOUD_SAMPLES, VANILLA_CLOUD_SUBSAMPLES);
  #endif
  #ifdef CUMULUS_CLOUDS
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skylightColor, transmit, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, CUMULUS_SAMPLES, CUMULUS_SUBSAMPLES);
  #endif
  #ifdef ALTOCUMULUS_CLOUDS
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skylightColor, transmit, ALTOCUMULUS_LOWER_HEIGHT, ALTOCUMULUS_UPPER_HEIGHT, ALTOCUMULUS_SAMPLES, ALTOCUMULUS_SUBSAMPLES);
  #endif
  #ifdef CIRRUS_CLOUDS
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skylightColor, transmit, CIRRUS_LOWER_HEIGHT, CIRRUS_UPPER_HEIGHT, CIRRUS_SAMPLES, CIRRUS_SUBSAMPLES);
  #endif

  scatter = max0(scatter);
  transmit = max0(transmit);

  LightInteraction interaction;
  interaction.scattering = scatter;
  interaction.transmittance = transmit;

  return interaction;
}

#endif // CLOUDS_GLSL