#ifndef CURL_GLSL
#define CURL_GLSL

#include "/lib/noise/perlin_noise.glsl"

vec3 sample_curl_noise(vec3 coord, float grid_size, int cell_dimensions) {
  vec3 curl;

  float n1 = sample_perlin_noise(
    coord + vec3(1.0, 0.0, 0.0),
    grid_size,
    cell_dimensions
  );
  float n2 = sample_perlin_noise(
    coord - vec3(1.0, 0.0, 0.0),
    grid_size,
    cell_dimensions
  );

  curl.x = (n1 - n2) / 2.0;

  n1 = sample_perlin_noise(
    coord + vec3(0.0, 1.0, 0.0),
    grid_size,
    cell_dimensions
  );
  n2 = sample_perlin_noise(
    coord - vec3(0.0, 1.0, 0.0),
    grid_size,
    cell_dimensions
  );

  curl.y = (n1 - n2) / 2.0;

  n1 = sample_perlin_noise(
    coord + vec3(0.0, 0.0, 1.0),
    grid_size,
    cell_dimensions
  );
  n2 = sample_perlin_noise(
    coord - vec3(0.0, 0.0, 1.0),
    grid_size,
    cell_dimensions
  );

  curl.z = (n1 - n2) / 2.0;

  return curl;
}

#endif // CURL_GLSL
