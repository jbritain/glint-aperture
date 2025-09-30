#ifndef BRDF_GLSL
#define BRDF_GLSL

vec3 brdf_diffuse(Material material, vec3 L) {
  if (material.metal_id != NO_METAL) return vec3(0.0);
  float NoL = saturate(dot(material.texture_normal, L));
  NoL *= step(0.0, dot(material.geometry_normal, L));

  return material.albedo * NoL;
}

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float get_NoH_squared(float NoL, float NoV, float VoL, float radius) {
  float radiusCos = cos(radius);
  float radiusTan = tan(radius);

  float RoL = 2.0 * NoL * NoV - VoL;
  if (RoL >= radiusCos) return 1.0;

  float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
  float NoTr = rOverLengthT * (NoV - RoL * NoL);
  float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

  float triple = sqrt(
    clamp(
      1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,
      0.0,
      1.0
    )
  );

  float NoBr = rOverLengthT * triple,
    VoBr = rOverLengthT * (2.0 * triple * NoV);
  float NoLVTr = NoL * radiusCos + NoV + NoTr,
    VoLVTr = VoL * radiusCos + 1.0 + VoTr;
  float p = NoBr * VoLVTr,
    q = NoLVTr * VoLVTr,
    s = VoBr * NoLVTr;
  float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
  float xDenom =
    p * p +
    s * (s - 2.0 * p) +
    NoLVTr *
      ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
        q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
  float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
  float sinTheta = twoX1 * xDenom;
  float cosTheta = 1.0 - twoX1 * xNum;
  NoTr = cosTheta * NoTr + sinTheta * NoBr;
  VoTr = cosTheta * VoTr + sinTheta * VoBr;

  float newNoL = NoL * radiusCos + NoTr;
  float newVoL = VoL * radiusCos + VoTr;
  float NoH = NoV + newNoL;
  float HoH = 2.0 * newVoL + 2.0;
  return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float schlick_ggx(float NoV, float K) {
  float nom = NoV;
  float denom = NoV * (1.0 - K) + K;

  return nom / denom;
}

float geometry_smith(vec3 N, vec3 V, vec3 L, float K) {
  float NoV = max(dot(N, V), 1e-6);
  float NoL = max(dot(N, L), 1e-6);
  float ggx1 = schlick_ggx(NoV, K);
  float ggx2 = schlick_ggx(NoL, K);

  return ggx1 * ggx2;
}

vec3 approximate_rough_normal(vec3 view_dir, vec3 normal, float roughness) {
  return normalize(mix(normal, normal + view_dir, roughness));
}

vec3 schlick(Material material, float NoV) {
  if (material.metal_id == NO_METAL) {
    // normal schlick approx.
    return saturate(vec3(material.f0 + (1.0 - material.f0) * pow5(1.0 - NoV)));
  } else if (material.metal_id == OTHER_METAL) {
    return saturate(
      material.albedo + (1.0 - material.albedo) * pow5(1.0 - NoV)
    );
  } else {
    vec3 f0 = get_metal_f0(material.metal_id);
    vec3 f82 = get_metal_f82(material.metal_id);
    // lazanyi schlick - https://www.shadertoy.com/view/DdlGWM
    vec3 a = 823543.0 / 46656.0 * (f0 - f82) + 49.0 / 6.0 * (1.0 - f0);

    float p1 = 1.0 - NoV;
    float p2 = p1 * p1;
    float p4 = p2 * p2;

    return saturate(f0 + ((1.0 - f0) * p1 - a * NoV * p2) * p4);
  }
}

vec3 brdf_specular_area(
  Material material,
  vec3 L,
  vec3 V,
  float angular_radius
) {
  vec3 N = material.texture_normal;
  vec3 H = normalize(L + V);

  float NoL = saturate(dot(material.texture_normal, L));
  NoL *= step(0.0, dot(material.geometry_normal, L));

  if (NoL < 1e-6) {
    return vec3(0.0);
  }

  float NoV = dot(N, V);
  float VoL = dot(V, L);
  float HoV = dot(H, V);

  float alpha = max(1e-3, material.roughness);
  float NoH_squared = get_NoH_squared(NoL, NoV, VoL, angular_radius);

  float denominator = NoH_squared * (pow2(alpha) - 1.0) + 1.0;
  float D = pow2(alpha) / (PI * pow2(denominator));
  float G = geometry_smith(N, V, L, material.roughness);

  return vec3(D * G / (4.0 * NoV + 1e-6));
}

// takes in a light vector that is NORMALIZED and a light radius IN RADIANS
vec3 brdf_specular(Material material, vec3 L, vec3 V) {
  vec3 N = material.texture_normal;
  vec3 H = normalize(L + V);

  float NoL = dot(material.texture_normal, L);
  NoL *= step(0.0, dot(material.geometry_normal, L));

  float NoV = dot(N, V);
  float VoL = dot(V, L);
  float HoV = dot(H, V);

  float alpha = max(1e-3, material.roughness);
  float NoH_squared = pow2(dot(N, H));

  float denominator = NoH_squared * (pow2(alpha) - 1.0) + 1.0;
  float D = pow2(alpha) / (PI * pow2(denominator));
  float G = geometry_smith(N, V, L, material.roughness);

  return vec3(D * G / (4.0 * NoV + 1e-6));
}

// https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
// Page 13 - 'area lights'

vec3 point_light_brdf(
  Material material,
  vec3 L,
  vec3 V,
  vec3 r, // reflected vector
  vec3 fresnel,
  float radius
) {
  vec3 diffuse = brdf_diffuse(material, normalize(L));
  diffuse = mix(diffuse, vec3(material.albedo), material.subsurface_scattering);

  vec3 N = material.texture_normal;

  vec3 centre_to_ray = dot(L, r) * r - L;
  vec3 l = L + centre_to_ray * saturate(radius / length(centre_to_ray));
  L = normalize(l);
  float distance = length(l);

  float alpha_prime = saturate(material.roughness + radius / (2.0 * distance));
  float normalization = pow2(material.roughness / alpha_prime);

  return mix(diffuse, brdf_specular(material, L, V), fresnel) *
  normalization *
  PI;
}

#endif // BRDF_GLSL
