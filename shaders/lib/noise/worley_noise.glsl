#ifndef WORLEY_GLSL
#define WORLEY_GLSL

vec3 rand(ivec3 p) {
  vec3 p3 = fract(vec3(p) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float sample_worley_noise(vec3 coord, float grid_size, int cell_dimensions) {
  float min_distance = 2.0;

  ivec3 cell = ivec3(floor(coord / grid_size));

  vec3 local_coord = fract(coord / grid_size);

  for (int x = -1; x <= 1; x++) {
    for (int y = -1; y <= 1; y++) {
      for (int z = -1; z <= 1; z++) {
        ivec3 sample_cell = (cell + ivec3(x, y, z)) % cell_dimensions;

        // a 0-1 coordinate within the cell
        vec3 cell_coord = rand(sample_cell);

        min_distance = min(
          min_distance,
          distance(local_coord, cell_coord + vec3(x, y, z))
        );
      }
    }
  }

  return min_distance;
}

float sample_worley_noise(
  vec3 coord,
  float grid_size,
  int cell_dimensions,
  int octaves
) {
  float noise = 0.0;
  float amplitude = 1.0;
  float weight = 0.0;

  for (int i = 0; i < octaves; i++) {
    float noise_sample = sample_worley_noise(
      coord / amplitude,
      grid_size,
      cell_dimensions
    );
    amplitude *= 0.5;
    noise += noise_sample * amplitude;
    weight += amplitude;
  }

  return noise / weight;
}

#endif // WORLEY_GLSL
