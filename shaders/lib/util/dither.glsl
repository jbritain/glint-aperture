#ifndef DITHER_GLSL
#define DITHER_GLSL

uniform sampler2D noise_tex;

// The MIT License
// Copyright © 2024 Pascal Gilcher
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
// This new method calculates the bayer matrix without recursion or loops,
// in a single, self contained estimator, for O(1) complexity
//
// The output is tilable and supports every size up to the maximum of 2^16 x 2^16
//
// Note: Above 4 levels requires floating point textures to store the result
//

#define MAX_LEVEL 5

float direct_bayer(uvec2 p, uint level) {
  //first, spread bits
  p = ((p ^ (p << 8))) & 0x00ff00ffu;
  p = ((p ^ (p << 4))) & 0x0f0f0f0fu;
  p = ((p ^ (p << 2))) & 0x33333333u;
  p = ((p ^ (p << 1))) & 0x55555555u;

  //interleave with bayer bit order
  uint i = (p.x ^ p.y) | (p.x << 1u);

  //reverse bits (single op on HLSL (the superior shading language)
  i = ((i & 0xaaaaaaaau) >> 1) | ((i & 0x55555555u) << 1);
  i = ((i & 0xccccccccu) >> 2) | ((i & 0x33333333u) << 2);
  i = ((i & 0xf0f0f0f0u) >> 4) | ((i & 0x0f0f0f0fu) << 4);
  i = ((i & 0xff00ff00u) >> 8) | ((i & 0x00ff00ffu) << 8);
  i = (i >> 16) | (i << 16);

  //shave off unused bits and normalize
  return float(i >> 32u - 2u * level) / float(1 << 2u * level);
}

// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
// adapted with help from balint and hardester
float interleaved_gradient_noise(vec2 coord) {
  return fract(52.9829189 * fract(0.06711056 * coord.x + 0.00583715 * coord.y));
}

float interleaved_gradient_noise(vec2 coord, int frame) {
  return interleaved_gradient_noise(coord + 5.588238 * (frame & 63));
}

uniform sampler3D blue_noise_tex;

vec3 blue_noise(vec2 coord, int frame) {
  return texelFetch(
    blue_noise_tex,
    ivec3(ivec2(coord) % 128, frame % 64),
    0
  ).rgb;
}

vec3 blue_noise(vec2 coord, int frame, int i) {
  const float g = 1.6180339887498948482;
  float a1 = rcp(g);
  float a2 = rcp(pow2(g));

  vec2 offset = vec2(fract(0.5 + a1 * i), fract(0.5 + a2 * i));
  return blue_noise(coord + offset * 128, frame);
}

#endif // DITHER_GLSL
