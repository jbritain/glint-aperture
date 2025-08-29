#ifndef MISC_GLSL
#define MISC_GLSL

#include "/lib/util/jessie_utils.glsl"

vec3 spherical_to_cartesian(vec2 coord) {
  float sin_theta = sin(coord.x);

  return vec3(
    sin(coord.y) * sin_theta,
    cos(coord.y),
    sin(coord.y) * cos(coord.x)
  );
}

vec2 cartesian_to_spherical(vec3 dir) {
  vec2 coord;
  coord.x = atan(dir.x, dir.z);
  coord.y = acos(dir.y);

  return mod(coord, TAU);
}

// TODO: fix these
vec3 hemispherical_to_cartesian(vec2 coord) {
  return spherical_to_cartesian(coord);
}

vec2 cartesian_to_hemispherical(vec3 dir) {
  return cartesian_to_spherical(dir);
}

// https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
mat3 generate_tbn(vec3 n) {
  mat3 tbn;
  tbn[2] = n;
  if (n.z < -0.9) {
    tbn[0] = vec3(0.0, -1, 0);
    tbn[1] = vec3(-1, 0, 0);
  } else {
    float a = 1.0 / (1.0 + n.z);
    float b = -n.x * n.y * a;
    tbn[0] = vec3(1.0 - n.x * n.x * a, b, -n.x);
    tbn[1] = vec3(b, 1.0 - n.y * n.y * a, -n.y);
  }
  return tbn;
}

vec2 vogel_disc_sample(int step_index, int step_count, float jitter) {
  float rotation = jitter * 2 * PI;
  const float golden_angle = 2.4;

  float r = sqrt(step_index + 0.5) / sqrt(float(step_count));
  float theta = step_index * golden_angle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

uint pcg_hash(uint seed) {
  uint state = seed * 747796405u + 2891336453u;
  uint word = ((state >> (state >> 28u) + 4u) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

float pcg_hash_normalized(uint seed) {
  return pcg_hash(seed) / float(0xffffffffu);
}

// https://nullprogram.com/blog/2018/07/31/
uint murmur_hash(uint x) {
  x ^= x >> 16;
  x *= 0x85ebca6bU;
  x ^= x >> 13;
  x *= 0xc2b2ae35U;
  x ^= x >> 16;
  return x;
}

float remap(
  float value,
  float original_min,
  float original_max,
  float new_min,
  float new_max
) {
  return new_min +
  (value - original_min) / (original_max - original_min) * (new_max - new_min);
}

bool ray_plane_intersection(
  vec3 origin,
  vec3 direction,
  float height,
  inout vec3 point
) {
  vec3 normal = vec3(0.0, sign(origin.y - height), 0.0); // plane normal vector
  vec3 plane_point = vec3(0.0, height, 0.0); // point on the plane

  float normal_dot_direction = dot(normal, direction);
  if (normal_dot_direction == 0.0) {
    return false;
  }

  float t = dot(normal, plane_point - origin) / normal_dot_direction;

  point = origin + t * direction;

  if (t < 0) {
    return false;
  }

  return true;
}

// https://github.com/Null-MC/Arc-2/blob/51330e693cf964b0e62180de21b075cbd2f88324/shaders/lib/sampling/catmull-rom.glsl
vec4 catmull_texture(sampler2D texSampler, vec2 uv) {
  vec2 bufferSize = textureSize(texSampler, 0);
  vec2 samplePos = uv * bufferSize;
  vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
  vec2 f = samplePos - texPos1;

  // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
  // These equations are pre-expanded based on our knowledge of where the texels will be located,
  // which lets us avoid having to evaluate a piece-wise function.
  vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
  vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
  vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
  vec2 w3 = f * f * (-0.5 + 0.5 * f);

  // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
  // simultaneously evaluate the middle 2 samples from the 4x4 grid.
  vec2 w12 = w1 + w2;
  vec2 offset12 = w2 / max(w12, 0.001);

  w0 = saturate(w0);
  w12 = saturate(w12);
  w3 = saturate(w3);

  // Compute the final UV coordinates we'll use for sampling the texture
  vec2 pixelSize = 1.0 / bufferSize;

  vec2 texPos0 = (texPos1 - 1.0) * pixelSize;
  vec2 texPos3 = (texPos1 + 2.0) * pixelSize;
  vec2 texPos12 = (texPos1 + offset12) * pixelSize;

  vec4 result = vec4(0.0);

  result += textureLod(texSampler, vec2(texPos0.x, texPos0.y), 0) * w0.x * w0.y;
  result +=
    textureLod(texSampler, vec2(texPos12.x, texPos0.y), 0) * w12.x * w0.y;
  result += textureLod(texSampler, vec2(texPos3.x, texPos0.y), 0) * w3.x * w0.y;

  result +=
    textureLod(texSampler, vec2(texPos0.x, texPos12.y), 0) * w0.x * w12.y;
  result +=
    textureLod(texSampler, vec2(texPos12.x, texPos12.y), 0) * w12.x * w12.y;
  result +=
    textureLod(texSampler, vec2(texPos3.x, texPos12.y), 0) * w3.x * w12.y;

  result += textureLod(texSampler, vec2(texPos0.x, texPos3.y), 0) * w0.x * w3.y;
  result +=
    textureLod(texSampler, vec2(texPos12.x, texPos3.y), 0) * w12.x * w3.y;
  result += textureLod(texSampler, vec2(texPos3.x, texPos3.y), 0) * w3.x * w3.y;

  return max(result, vec4(0.0));
}

#endif // MISC_GLSL
