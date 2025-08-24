#ifndef COMMON_GLSL
#define COMMON_GLSL

layout(rgba8) uniform image2D debug;

void _show(vec4 x, ivec2 fragCoord){
  imageStore(debug, fragCoord, x);
}

void _show(vec3 x, ivec2 fragCoord){
  _show(vec4(x, 1.0), fragCoord);
}

void _show(vec2 x, ivec2 fragCoord){
  _show(vec3(x, 0.0), fragCoord);
}

void _show(float x, ivec2 fragCoord){
  _show(vec3(x), fragCoord);
}

void _show(bool x, ivec2 fragCoord){
  _show(float(x), fragCoord);
}

#define show(x) _show(x, ivec2(gl_FragCoord.xy))

const float PI = radians(180);
const float TAU = PI * 2.0;

vec3 sun_dir = normalize(ap.celestial.sunPos);
vec3 light_dir = normalize(ap.celestial.pos);
vec3 world_sun_dir = mat3(ap.camera.viewInv) * sun_dir;
vec3 world_light_dir = mat3(ap.camera.viewInv) * light_dir;
// vec3 world_light_dir = -ap.celestial.view[2].xyz;
// vec3 world_sun_dir = sun_dir == light_dir ? world_light_dir : -world_light_dir;
float world_time_counter = ((ap.world.time / 20.0) + (ap.world.day * 1200.0));

const float isotropic_phase = 1.0 / (4.0 * PI);

// macro wizardry by BruceKnowsHow
#define DEFINE_genFType(func)                                                  \
  func ( float ) func ( vec2 ) func ( vec3 ) func ( vec4 )
#define DEFINE_genVType(func) func ( vec2 ) func ( vec3 ) func ( vec4 )
#define DEFINE_genDType(func)                                                  \
  func ( double ) func ( dvec2 ) func ( dvec3 ) func ( dvec4 )
#define DEFINE_genIType(func)                                                  \
  func ( int ) func ( ivec2 ) func ( ivec3 ) func ( ivec4 )
#define DEFINE_genUType(func)                                                  \
  func ( uint ) func ( uvec2 ) func ( uvec3 ) func ( uvec4 )
#define DEFINE_genBType(func)                                                  \
  func ( bool ) func ( bvec2 ) func ( bvec3 ) func ( bvec4 )

#define rcp_(type)                                                             \
  type rcp(type x) {                                                           \
    return 1.0 / x;                                                            \
  }
#define pow2_(type)                                                            \
  type pow2(type x) {                                                          \
    return x * x;                                                              \
  }
#define pow3_(type)                                                            \
  type pow3(type x) {                                                          \
    return x * x * x;                                                          \
  }
#define pow4_(type)                                                            \
  type pow4(type x) {                                                          \
    x *= x;                                                                    \
    return x * x;                                                              \
  }
#define pow5_(type)                                                            \
  type pow5(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x;                                                        \
  }
#define pow6_(type)                                                            \
  type pow6(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x2;                                                       \
  }
#define pow7_(type)                                                            \
  type pow7(type x) {                                                          \
    type x2 = x * x;                                                           \
    return x2 * x2 * x2 * x;                                                   \
  }
#define pow8_(type)                                                            \
  type pow8(type x) {                                                          \
    x *= x;                                                                    \
    x *= x;                                                                    \
    return x * x;                                                              \
  }

#define linearstep_(type)                                                      \
  type linearstep(type edge0, type edge1, type x) {                            \
    return clamp((x - edge0) / (edge1 - edge0), type(0.0), type(1.0));         \
  }

#define distance_squared_(type)                                                \
  float distance_squared(type a, type b) {                                      \
    a -= b;                                                                    \
    return dot(a, a);                                                          \
  }

#define swap_(type)                                                            \
  void swap(inout type a, inout type b) {                                      \
    type c = a;                                                                \
    a = b;                                                                     \
    b = c;                                                                     \
  }

DEFINE_genFType(rcp_)
DEFINE_genFType(pow2_)
DEFINE_genFType(pow3_)
DEFINE_genFType(pow4_)
DEFINE_genFType(pow5_)
DEFINE_genFType(pow6_)
DEFINE_genFType(pow7_)
DEFINE_genFType(pow8_)
DEFINE_genFType(linearstep_)
DEFINE_genVType(distance_squared_)
DEFINE_genFType(swap_)

#define saturate(x) clamp(x, 0.0, 1.0)

#define max0(x) max(x, 0.0)
#define max1(x) max(x, 1.0)
#define min0(x) min(x, 0.0)
#define min1(x) min(x, 1.0)

#define RED vec3(1.0, 0.0, 0.0)
#define GREEN vec3(0.0, 1.0, 0.0)
#define BLUE vec3(0.0, 0.0, 1.0)
#define WHITE vec3(1.0)
#define BLACK vec3(0.0)

#define sum2(v) ((v).x + (v).y)
#define sum3(v) ((v).x + (v).y + (v).z)
#define sum4(v) ((v).x + (v).y + (v).z + (v).w)

float max_vec2(vec2 v){
  return max(v.x, v.y);
}

float max_vec3(vec3 v){
  return max(v.x, max_vec2(v.yz));
}

float max_vec4(vec4 v){
  return max(max_vec2(v.xy), max_vec2(v.zw));
}

float min_vec2(vec2 v){
  return min(v.x, v.y);
}

float min_vec3(vec3 v){
  return min(v.x, min_vec2(v.yx));
}

float min_vec4(vec3 v){
  return min(min_vec2(v.xy), min_vec2(v.yz));
}

float mean2(vec2 v) {
  return sum2(v) / 2.0;
}

float mean3(vec3 v) {
  return sum3(v) / 3.0;
}

float mean4(vec4 v) {
  return sum4(v) / 4.0;
}

struct Ray {
  vec3 origin;
  vec3 direction;
};

struct Volume {
  vec3 transmittance;
  vec3 scattering;
};


float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}


#endif // COMMON_GLSL
