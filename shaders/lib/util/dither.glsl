#ifndef DITHER_GLSL
#define DITHER_GLSL

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

#endif // DITHER_GLSL
