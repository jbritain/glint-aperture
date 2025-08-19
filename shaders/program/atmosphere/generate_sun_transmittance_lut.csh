/*
    Hillaire, S. (2020). A Scalable and Production Ready Sky and Atmosphere Rendering Technique.  https://sebh.github.io/publications/egsr2020.pdf
*/

#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

#include "/lib/common.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/intersections.glsl"

layout(rgba16f) uniform image2D sun_transmittance_lut;

void main() {
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(sun_transmittance_lut);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;

  uv = saturate(uv);

  Ray ray = un_parameterise_sun_transmittance(uv);

  vec3 transmittance = vec3(1.0);

  vec3 target_pos;

  // // the sun cannot shine through the planet
  // if (ray_sphere_intersection(ray, vec3(0.0), earth_radius, target_pos)) {
  //   imageStore(sun_transmittance_lut, texel_coord, vec4(vec3(0.0), 1.0));
  //   return;
  // }

  ray_sphere_intersection(ray, vec3(0.0), atmosphere_radius, target_pos);

  #define SUN_TRANSMITTANCE_STEPS 40u
  vec3 ray_pos = ray.origin;
  vec3 ray_step = (target_pos - ray_pos) / SUN_TRANSMITTANCE_STEPS;
  float step_length = length(ray_step);

  ray_pos -= ray_step * 0.5; // to centre us in each step

  for (uint i = 0u; i < SUN_TRANSMITTANCE_STEPS; i++) {
    float altitude = max0(length(ray_pos) - earth_radius);

    float rayleigh_density = rayleigh_density(altitude);
    float mie_density = mie_density(altitude);
    float ozone_density = ozone_density(altitude);

    vec3 extinction = vec3(0.0);
    extinction += rayleigh_scattering_coeff * rayleigh_density;
    extinction += mie_scattering_coeff * mie_density;

    extinction += rayleigh_absorption_coeff * rayleigh_density;
    extinction += mie_absorption_coeff * mie_density;
    extinction += ozone_absorption_coeff * ozone_density;

    transmittance *= exp(-extinction * step_length);

    ray_pos += ray_step;
  }

  imageStore(sun_transmittance_lut, texel_coord, vec4(transmittance, 1.0));

}
