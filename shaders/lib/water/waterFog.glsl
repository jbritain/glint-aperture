#ifndef WATER_FOG_GLSL
#define WATER_FOG_GLSL

#define WATER_ABSORPTION vec3(0.3, 0.09, 0.04)
#define WATER_SCATTERING vec3(0.01, 0.06, 0.05)
#define WATER_DENSITY 1.0

const vec3 waterExtinction = clamp01(WATER_ABSORPTION + WATER_SCATTERING);

vec3 waterFog(out vec3 transmittance, vec3 a, vec3 b){
  vec3 opticalDepth = waterExtinction * WATER_DENSITY * distance(a, b);
  transmittance = exp(-opticalDepth);
  return clamp01((transmittance - 1.0) / -opticalDepth) * WATER_SCATTERING * (sunlightColor * getMiePhase(dot(normalize(b - a), lightDir)) + skylightColor);
}

#endif