#ifndef VNDF_GLSL
#define VNDF_GLSL

#include "/lib/common.glsl"

// by Zombye
// https://discord.com/channels/237199950235041794/525510804494221312/1118170604160421918
// https://ggx-research.github.io/publication/2023/06/09/publication-ggx.html
vec3 sample_vndf_ggx(
  vec3 viewer_direction, // Direction pointing towards the viewer, oriented such that +Z corresponds to the surface normal
  vec2 alpha, // Roughness parameter along X and Y of the distribution
  vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
  // Transform viewer direction to the hemisphere configuration
  viewer_direction = normalize(
    vec3(alpha * viewer_direction.xy, viewer_direction.z)
  );

  // Sample a reflection direction off the hemisphere
  float phi = TAU * xy.x;
  float cos_theta = fma(
    1.0 - xy.y,
    1.0 + viewer_direction.z,
    -viewer_direction.z
  );
  float sin_theta = sqrt(clamp(1.0 - cos_theta * cos_theta, 0.0, 1.0));
  vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sin_theta, cos_theta);

  // Evaluate halfway direction
  // This gives the normal on the hemisphere
  vec3 halfway = reflected + viewer_direction;

  // Transform the halfway direction back to hemiellispoid configuation
  // This gives the final sampled normal
  return normalize(vec3(alpha * halfway.xy, halfway.z));
}

#endif // VNDF_GLSL
