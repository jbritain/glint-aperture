#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

#include "/lib/buffers/scene_data.glsl"
#include "/lib/common.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/dither.glsl"

uniform sampler2D cloud_spheremap_tex;

layout(rgba16f) uniform image2D sky_irradiance_lut;

void main() {
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(sky_irradiance_lut);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;

  vec3 dir = spherical_to_cartesian(uv * TAU);

  #define SKY_IRRADIANCE_SQRT_SAMPLES 10

  vec3 col = vec3(0.0);
  vec3 col_without_clouds = vec3(0.0);

  for (int i = 0; i < SKY_IRRADIANCE_SQRT_SAMPLES; i++) {
    for (int j = 0; j < SKY_IRRADIANCE_SQRT_SAMPLES; j++) {
      vec2 coeffs = (vec2(i, j) + 0.5) / float(SKY_IRRADIANCE_SQRT_SAMPLES);
      float cos_theta = sqrt(coeffs.x);
      float sin_theta = sqrt(1.0 - pow2(cos_theta));
      float phi = coeffs.y * TAU;

      vec3 sample_dir = normalize(rotate(
        vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, cos_theta),
        vec3(0.0, 0.0, 1.0),
        dir
      ));

      vec3 sky = get_sky(sample_dir, false);
      col_without_clouds += sky;
      vec4 clouds = texture(cloud_spheremap_tex, cartesian_to_hemispherical(sample_dir) / TAU);
      sky = fma(sky, vec3(clouds.a), clouds.rgb);
      col += sky;
    }
  }

  col /= float(pow2(SKY_IRRADIANCE_SQRT_SAMPLES));

  if(dir.y > 0.98 && dir.z == 0.0 && uv.y > 0.5) {
    col_without_clouds /= float(pow2(SKY_IRRADIANCE_SQRT_SAMPLES));
    skylight_color = col_without_clouds;
  }


  imageStore(sky_irradiance_lut, texel_coord, vec4(col, 1.0));

}
