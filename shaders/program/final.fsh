#version 460 core

uniform sampler2D sceneTex;
uniform sampler2D bloomTex;

#include "/lib/common.glsl"

in vec2 uv;
out vec4 fragColor;

vec3 uncharted2TonemapPartial(vec3 x)
{
    float A = 0.15f;
    float B = 0.50f;
    float C = 0.10f;
    float D = 0.20f;
    float E = 0.02f;
    float F = 0.30f;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 uncharted2FilmicTonemap(vec3 v)
{
    float exposure_bias = 2.0f;
    vec3 curr = uncharted2TonemapPartial(v * exposure_bias);

    vec3 W = vec3(11.2f);
    vec3 white_scale = vec3(1.0f) / uncharted2TonemapPartial(W);
    return pow(curr * white_scale, vec3(rcp(2.2)));
}

vec3 ACESFilm(vec3 x){
    x *= 0.5;
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return pow(clamp01((x*(a*x+b))/(x*(c*x+d)+e)), vec3(rcp(2.2)));
}

#define AGX_LOOK 2

// AgX
// ->

// Mean error^2: 3.6705141e-06
vec3 agxDefaultContrastApprox(vec3 x) {
  vec3 x2 = x * x;
  vec3 x4 = x2 * x2;
  
  return + 15.5     * x4 * x2
         - 40.14    * x4 * x
         + 31.96    * x4
         - 6.868    * x2 * x
         + 0.4298   * x2
         + 0.1191   * x
         - 0.00232;
}

vec3 agx(vec3 val) {
  const mat3 agx_mat = mat3(
    0.842479062253094, 0.0423282422610123, 0.0423756549057051,
    0.0784335999999992,  0.878468636469772,  0.0784336,
    0.0792237451477643, 0.0791661274605434, 0.879142973793104);
    
  const float min_ev = -12.47393f;
  const float max_ev = 4.026069f;

  // Input transform
  val = agx_mat * val;
  
  // Log2 space encoding
  val = clamp(log2(val), min_ev, max_ev);
  val = (val - min_ev) / (max_ev - min_ev);
  
  // Apply sigmoid function approximation
  val = agxDefaultContrastApprox(val);

  return val;
}

vec3 agxEotf(vec3 val) {
  const mat3 agx_mat_inv = mat3(
    1.19687900512017, -0.0528968517574562, -0.0529716355144438,
    -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
    -0.0990297440797205, -0.0989611768448433, 1.15107367264116);
    
  // Undo input transform
  val = agx_mat_inv * val;
  
  // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display
  //val = pow(val, vec3(2.2));

  return val;
}

vec3 agxLook(vec3 val) {
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

vec3 agxTonemap(vec3 col){
    col = agx(col);
    col = agxLook(col);
    col = agxEotf(col);
    return col;
}

uniform sampler2D debugTex;

void main() {
	fragColor = texture(sceneTex, uv);

  #ifdef BLOOM_ENABLE
  fragColor.rgb = mix(fragColor.rgb, texture(bloomTex, uv).rgb, 0.01);
  #endif

  fragColor.rgb *= 0.5;

	fragColor.rgb = agxTonemap(fragColor.rgb);

  #ifdef DEBUG_ENABLE
  fragColor.rgb = texture(debugTex, uv).rgb;
  #endif


}
