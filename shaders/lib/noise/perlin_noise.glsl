#ifndef PERLIN_GLSL
#define PERLIN_GLSL

// Implemented from "Understanding Perlin Noise" from Adrian's soapbox
// https://adrianb.io/2014/08/09/perlinnoise.html

// Hash lookup table as defined by Ken Perlin. This is a randomly arranged array of all numbers from 0-255 inclusive.
// prettier-ignore
const int permutations[] = int[](
  151,160,137,91,90,15,                 
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
);

int p(int i) {
  return permutations[i % 255];
}

// Fade function as defined by Ken Perlin. This eases coordinate values so that they will ease towards integral values. This ends up smoothing the final output.
float fade(float t) {
  return t * t * t * (t * (t * 6 - 15) + 10); // 6t^5 - 15t^4 + 10t^3
}

// Source: http://riven8192.blogspot.com/2010/08/calculate-perlinnoise-twice-as-fast.html
// prettier-ignore
float grad(int hash, float x, float y, float z) {
  switch(hash & 0xF) {
    case 0x0: return  x + y;
    case 0x1: return -x + y;
    case 0x2: return  x - y;
    case 0x3: return -x - y;
    case 0x4: return  x + z;
    case 0x5: return -x + z;
    case 0x6: return  x - z;
    case 0x7: return -x - z;
    case 0x8: return  y + z;
    case 0x9: return -y + z;
    case 0xA: return  y - z;
    case 0xB: return -y - z;
    case 0xC: return  y + x;
    case 0xD: return -y + z;
    case 0xE: return  y - x;
    case 0xF: return -y - z;
    default: return 0; // never happens
  }
}

int inc(int num, int cell_dimensions) {
  return (num + 1) % cell_dimensions;
}

float perlin(vec3 vec, int cell_dimensions) {
  vec = mod(vec, vec3(cell_dimensions));

  int xi = int(vec.x) & 255; // Calculate the "unit cube" that the point asked will be located in
  int yi = int(vec.y) & 255; // The left bound is ( |_x_|,|_y_|,|_z_| ) and the right bound is that
  int zi = int(vec.z) & 255; // plus 1.  Next we calculate the location (from 0.0 to 1.0) in that cube.

  float xf = fract(vec.x);
  float yf = fract(vec.y);
  float zf = fract(vec.z);

  float u = fade(xf);
  float v = fade(yf);
  float w = fade(zf);

  int aaa, aba, aab, abb, baa, bba, bab, bbb;
  // prettier-ignore
  {
    aaa = p(p(p(xi) + yi) + zi);
    aba = p(p(p(xi) + inc(yi, cell_dimensions)) + zi);
    aab = p(p(p(xi) + yi) + inc(zi, cell_dimensions));
    abb = p(p(p(xi) + inc(yi, cell_dimensions)) + inc(zi, cell_dimensions));
    baa = p(p(p(inc(xi, cell_dimensions)) + yi) + zi);
    bba = p(p(p(inc(xi, cell_dimensions)) + inc(yi, cell_dimensions)) + zi);
    bab = p(p(p(inc(xi, cell_dimensions)) + yi) + inc(zi, cell_dimensions));
    bbb = p(p(p(inc(xi, cell_dimensions)) + inc(yi, cell_dimensions)) + inc(zi, cell_dimensions));
  }

  float x1, x2, y1, y2;

  x1 = mix(
    grad(aaa, xf, yf, zf), // The gradient function calculates the dot product between a pseudorandom
    grad(baa, xf - 1, yf, zf), // gradient vector and the vector from the input coordinate to the 8
    u
  ); // surrounding points in its unit cube.
  x2 = mix(
    grad(aba, xf, yf - 1, zf), // This is all then mixed together as a sort of weighted average based on the faded (u,v,w)
    grad(bba, xf - 1, yf - 1, zf), // values we made earlier.
    u
  );
  y1 = mix(x1, x2, v);

  x1 = mix(grad(aab, xf, yf, zf - 1), grad(bab, xf - 1, yf, zf - 1), u);
  x2 = mix(grad(abb, xf, yf - 1, zf - 1), grad(bbb, xf - 1, yf - 1, zf - 1), u);
  y2 = mix(x1, x2, v);

  return (mix(y1, y2, w) + 1) / 2;
}

float sample_perlin_noise(vec3 coord, float grid_size, int cell_dimensions) {
  return perlin(vec3(coord / grid_size), cell_dimensions);
}

float sample_perlin_noise(
  vec3 coord,
  float grid_size,
  int cell_dimensions,
  int octaves
) {
  float noise = 0.0;
  float amplitude = 1.0;
  float weight = 0.0;

  for (int i = 0; i < octaves; i++) {
    float noise_sample = sample_perlin_noise(
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

#endif // PERLIN_GLSL
