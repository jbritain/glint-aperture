#ifndef TONEMAP_GLSL
#define TONEMAP_GLSL

vec3 jodie_reinhard_tonemap(vec3 v) {
  float l = dot(v, vec3(0.2126, 0.7152, 0.0722));
  vec3 tv = v / (1.0f + v);
  return pow(mix(v / (1.0f + l), tv, tv), vec3(rcp(GAMMA)));
}

vec3 uncharted2_tonemap_partial(vec3 x) {
  float A = 0.15f;
  float B = 0.50f;
  float C = 0.10f;
  float D = 0.20f;
  float E = 0.02f;
  float F = 0.30f;
  return (x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F) - E / F;
}

vec3 uncharted2_filmic_tonemap(vec3 v) {
  float exposure_bias = 2.0f;
  vec3 curr = uncharted2_tonemap_partial(v * exposure_bias);

  vec3 W = vec3(11.2f);
  vec3 white_scale = vec3(1.0f) / uncharted2_tonemap_partial(W);
  return pow(curr * white_scale, vec3(rcp(GAMMA)));
}

vec3 hejl_burgess_tonemap(vec3 v) {
  v /= 2.0;
  vec3 x = max0(v - 0.004);
  return x * (6.2 * x + 0.5) / (x * (6.2 * x + 1.7) + 0.06);
}

vec3 aces_tonemap(vec3 v) {
  v *= 0.5;

  float a = 2.51;
  float b = 0.03;
  float c = 2.43;
  float d = 0.59;
  float e = 0.14;
  return pow(
    saturate(v * (a * v + b) / (v * (c * v + d) + e)),
    vec3(rcp(GAMMA))
  );
}

// 0: Default, 1: Golden, 2: Punchy
#define AGX_LOOK 2

// AgX
// ->

// Mean error^2: 3.6705141e-06
vec3 agx_default_contrast_approx(vec3 x) {
  vec3 x2 = x * x;
  vec3 x4 = x2 * x2;

  return +15.5 * x4 * x2 -
  40.14 * x4 * x +
  31.96 * x4 -
  6.868 * x2 * x +
  0.4298 * x2 +
  0.1191 * x -
  0.00232;
}

vec3 agx(vec3 val) {
  const mat3 agx_mat = mat3(
    0.842479062253094 , 0.0423282422610123, 0.0423756549057051,
    0.0784335999999992, 0.878468636469772 , 0.0784336         ,
    0.0792237451477643, 0.0791661274605434, 0.879142973793104
  );

  const float min_ev = -12.47393f;
  const float max_ev = 4.026069f;

  // Input transform
  val = agx_mat * val;

  // Log2 space encoding
  val = clamp(log2(val), min_ev, max_ev);
  val = (val - min_ev) / (max_ev - min_ev);

  // Apply sigmoid function approximation
  val = agx_default_contrast_approx(val);

  return val;
}

vec3 agx_eotf(vec3 val) {
  const mat3 agx_mat_inv = mat3(
     1.19687900512017  , -0.0528968517574562, -0.0529716355144438,
    -0.0980208811401368,  1.15190312990417  , -0.0980434501171241,
    -0.0990297440797205, -0.0989611768448433,  1.15107367264116
  );

  // Undo input transform
  val = agx_mat_inv * val;

  // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display
  val = pow(val, vec3(GAMMA));

  return val;
}

vec3 agx_look(vec3 val) {
  const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
  float luma = dot(val, lw);

  // Default
  vec3 offset = vec3(0.0);
  vec3 slope = vec3(1.0);
  vec3 power = vec3(1.0);
  float sat = 1.0;

  #if AGX_LOOK == 1
  // Golden
  slope = vec3(1.0, 0.9, 0.5);
  power = vec3(0.8);
  sat = 0.8;
  #elif AGX_LOOK == 2
  // Punchy
  slope = vec3(1.0);
  power = vec3(1.35, 1.35, 1.35);
  sat = 1.4;
  #endif

  // ASC CDL
  val = pow(val * slope + offset, power);
  return luma + sat * (val - luma);
}

vec3 agx_tonemap(vec3 col) {
  col *= 2.0;
  col = agx(col);
  col = agx_look(col);
  col = agx_eotf(col);
  return col;
}

// https://github.com/dmnsgn/glsl-tone-map/blob/main/lottes.glsl
vec3 lottes_tonemap(vec3 x) {
  x *= 0.4;

  const vec3 a = vec3(1.6);
  const vec3 d = vec3(0.977);
  const vec3 hdr_max = vec3(8.0);
  const vec3 mid_in = vec3(0.18);
  const vec3 mid_out = vec3(0.267);

  const vec3 b =
    (-pow(mid_in, a) + pow(hdr_max, a) * mid_out) /
    ((pow(hdr_max, a * d) - pow(mid_in, a * d)) * mid_out);
  const vec3 c =
    (pow(hdr_max, a * d) * pow(mid_in, a) -
      pow(hdr_max, a) * pow(mid_in, a * d) * mid_out) /
    ((pow(hdr_max, a * d) - pow(mid_in, a * d)) * mid_out);

  return pow(pow(x, a) / (pow(x, a * d) * b + c), vec3(rcp(GAMMA)));
}

uniform sampler3D tony_mc_mapface_tex;

// https://github.com/h3r2tic/tony-mc-mapface/
vec3 tony_mc_mapface(vec3 stimulus) {
  stimulus *= 3.0;

  // Apply a non-linear transform that the LUT is encoded with.
  vec3 encoded = stimulus / (stimulus + 1.0);

  // Align the encoded range to texel centers.
  const float LUT_DIMS = 48.0;
  vec3 coord = encoded * ((LUT_DIMS - 1.0) / LUT_DIMS) + 0.5 / LUT_DIMS;

  return texture(tony_mc_mapface_tex, coord).rgb;
}
#define tonemap tony_mc_mapface

#endif // TONEMAP_GLSL
