#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/atmosphericFog.glsl"

#define CLOUD_DISTANCE 100000.0
#define CUMULUS_LOWER_HEIGHT 200
#define CUMULUS_UPPER_HEIGHT 800

#define CLOUD_EXTINCTION_COLOR vec3(0.2 + ap.world.rainStrength * 0.2)

#define CUMULUS_SAMPLES 16
#define CUMULUS_SUBSAMPLES 8

float getCloudDensity(vec3 pos){
  if(clamp(pos.y, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT) != pos.y) return 0.0;
  float heightInPlane = linearstep(CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, pos.y);

  vec3 samplePos = pos * 0.0007;

  vec3 wind = -ap.time.elapsed * vec3(0.0, 1.0, 0.2) * 0.0;

  vec4 lowFreq = texture(cloudShapeNoiseTex, fract(samplePos + wind * 0.01));

  float lowFreqFBM = lowFreq.g * 0.625 + lowFreq.b * 0.25 + lowFreq.a * 0.125;

  float density = (lowFreq.r);
  density = remap(density, lowFreqFBM - 1.0 , 1.0, 0.0, 1.0);

  if(density < 0.01) return 0.0;

  float type = texture(perlinNoiseTex, fract(samplePos.xz * 0.005)).r;

  vec2 heightGradientCoord = vec2(type, 1.0 - heightInPlane);

  density *= texture(cloudHeightGradientTex, heightGradientCoord).r;

  float coverage = smoothstep(0.5, 1.0, 1.0 - texture(worleyNoiseTex, fract(samplePos.xz * 0.1 + wind.xz * 0.001)).r);
  coverage = clamp01(coverage + ap.world.rainStrength * 0.5);

  density = remap(density, 1.0 - coverage, 1.0, 0.0, 1.0);

  if(density < 0.01) return 0.0;

  vec3 highFreq = texture(cloudErosionNoiseTex, fract(samplePos * 10.0 + wind * 0.1)).rgb;
  float highFreqFBM = highFreq.r * 0.625 + highFreq.g * 0.25 + highFreq.b * 0.125;

  highFreqFBM = mix(highFreqFBM, 1.0 - highFreqFBM, clamp01(heightInPlane * 10.0));
  density = remap(density, highFreqFBM, 1.0, 0.0, 1.0);

  density = max0(density);

  return density;
}

float getTotalDensityTowardsLight(vec3 rayPos, float jitter, float lowerHeight, float upperHeight, int samples){
  vec3 a = rayPos;
  vec3 b = rayPos;

  vec3 dir = worldLightDir;
  vec3 tempPoint = a + dir * 2.0;
  tempPoint += blueNoise(uv, pow2(ap.time.frames)).xyz * 2.0 - 1.0;
  dir = normalize(tempPoint - a);

  samples = int(mix(float(samples), samples * 2.0, 1.0 - abs(dir.y)));

  bool goingDown = dir.y < 0;
  bool belowLayer = rayPos.y < lowerHeight;
  if(goingDown != belowLayer) return 0.0;

  if(!rayPlaneIntersection(rayPos, dir, lowerHeight, b)){ 
    rayPlaneIntersection(rayPos, dir, upperHeight, b);
  }

  vec3 increment = (b - a) / float(samples);

  vec3 subRayPos = a;
  float totalDensity = 0.0;

  subRayPos += increment * jitter;

  for(int i = 0; i < samples; i++){
    subRayPos += increment;
    totalDensity += getCloudDensity(subRayPos) * length(increment);
  }

  return totalDensity;
}

// march from a ray position towards the sun to calculate how much light makes it there
vec3 calculateCloudLightEnergy(vec3 rayPos, float jitter, float costh, int samples){
  float totalDensity = 0.0;
  totalDensity += getTotalDensityTowardsLight(rayPos, jitter, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, samples);

  // float beers = exp(-totalDensity);
  // float powder = 1.0 - exp(-totalDensity * 2.0);

  // vec3 transmit = vec3(beers);//vec3(2.0 * beers * powder);
  // return clamp01(transmit) * dualHenyeyGreenstein(0.8, -0.5, costh, 0.5);

  vec3 powder = clamp01((1.0 - exp(-totalDensity * 2.0 * CLOUD_EXTINCTION_COLOR)));
  vec3 beers = clamp01(exp(-totalDensity * CLOUD_EXTINCTION_COLOR));

  return multipleScattering(totalDensity, costh, 0.8, -0.5, CLOUD_EXTINCTION_COLOR, 4, 0.5, 0.9, 0.8, 0.1) * beers;// * powder 2.0;
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
  vec2 noise = blueNoise(uv).rg;
  #else
  vec2 noise = blueNoise(uv, ap.time.frames).rg;
  #endif
  float jitter = noise.x;
  float lightJitter = noise.y;
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
  scatter += marchCloudLayer(playerPos, depth, sunlightColor, skylightColor, transmit, CUMULUS_LOWER_HEIGHT, CUMULUS_UPPER_HEIGHT, CUMULUS_SAMPLES, CUMULUS_SUBSAMPLES);

  scatter = max0(scatter);
  transmit = max0(transmit);

  LightInteraction interaction;
  interaction.scattering = scatter;
  interaction.transmittance = transmit;

  return interaction;
}

#endif // CLOUDS_GLSL