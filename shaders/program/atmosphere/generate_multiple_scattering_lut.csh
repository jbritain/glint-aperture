/*
    Hillaire, S. (2020). A Scalable and Production Ready Sky and Atmosphere Rendering Technique.  https://sebh.github.io/publications/egsr2020.pdf
    Also based on code from 'Production Sky Rendering' by Andrew Helmer. https://www.shadertoy.com/view/slSXRW
*/

#version 460 core

layout (local_size_x = 8, local_size_y = 8) in;

#include "/lib/common.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/intersections.glsl"
#include "/lib/util/misc.glsl"

uniform sampler2D sun_transmittance_lut_tex;

layout(rgba16f) uniform image2D multiple_scattering_lut;

void main() {
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(multiple_scattering_lut);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;
  
  Ray sun_vector = un_parameterise_multiple_scattering(uv);

  #define MULTIPLE_SCATTERING_STEPS 20u
  #define MULTIPLE_SCATTERING_SQRT_SAMPLES 8u

  vec3 total_luminance = vec3(0.0);
  vec3 psi_ms = vec3(0.0);

  float inverse_samples = 1.0 / pow2(MULTIPLE_SCATTERING_SQRT_SAMPLES);

  // basically, we march in a bunch of directions around the sample point to gather second order scattering values
  // we also gather third order scattering by taking samples with no phase function (I think?)
  for (uint i = 0u; i < MULTIPLE_SCATTERING_SQRT_SAMPLES; i++){
    for (uint j = 0u; j < MULTIPLE_SCATTERING_SQRT_SAMPLES; j++){
      Ray ray;

      float theta = PI * (float(i) + 0.5) / float(MULTIPLE_SCATTERING_SQRT_SAMPLES); // only integrating over a hemisphere because the integral is symmetric
      float phi = acos(saturate(1.0 - 2.0 * (float(j) + 0.5) / float(MULTIPLE_SCATTERING_SQRT_SAMPLES)));

      ray.direction = spherical_to_cartesian(theta, phi);
      ray.origin = sun_vector.origin;

      vec3 test_point;

      // TODO: handle outside atmosphere case

      bool intersects_ground = ray_sphere_intersection(ray, vec3(0.0), earth_radius, test_point);
      float t_max = distance(ray.origin, test_point);
      if(t_max <= 0.0){
        ray_sphere_intersection(ray, vec3(0.0), atmosphere_radius, test_point);
        t_max = distance(ray.origin, test_point);
      }

      vec3 luminance = vec3(0.0);
      vec3 luminance_factor = vec3(0.0);
      vec3 transmittance = vec3(1.0);
      float t = 0.0;

      float cos_theta = dot(ray.direction, world_sun_dir);
      float rayleigh_phase = rayleigh_phase(cos_theta);
      float mie_phase = mie_phase(cos_theta);

      for (float step_i = 0.0; step_i < float(MULTIPLE_SCATTERING_STEPS); step_i += 1.0){
        float new_t = ((step_i + 0.3) / MULTIPLE_SCATTERING_STEPS) * t_max;
        float d_t = new_t - t;

        t = new_t;

        vec3 new_pos = ray.origin + t * ray.direction;
        float altitude = max0(length(new_pos));

        float rayleigh_density = rayleigh_density(altitude);
        float mie_density = mie_density(altitude);
        float ozone_density = ozone_density(altitude);

        vec3 rayleigh_scattering = rayleigh_scattering_coeff * rayleigh_density;
        vec3 mie_scattering = mie_scattering_coeff * mie_density;

        vec3 extinction = rayleigh_scattering + mie_scattering;

        extinction += rayleigh_absorption_coeff * rayleigh_density;
        extinction += mie_absorption_coeff * mie_density;
        extinction += ozone_absorption_coeff * ozone_density;

        vec3 sample_transmittance = exp(-extinction * d_t);

        // second order sca
        vec3 scattering_no_phase = rayleigh_scattering + mie_scattering;
        vec3 scattering_no_phase_integral = (scattering_no_phase - scattering_no_phase * sample_transmittance) / extinction;
        luminance_factor += transmittance * scattering_no_phase_integral;

        Ray sample_sun_ray;
        sample_sun_ray.origin = new_pos;
        sample_sun_ray.direction = world_sun_dir;
        vec3 sun_transmittance = texture(sun_transmittance_lut_tex, parameterise_sun_transmittance(sample_sun_ray)).rgb;

        vec3 scattering = rayleigh_scattering * rayleigh_phase + mie_scattering * mie_phase;
        vec3 scattering_integral = (scattering - scattering * sample_transmittance) / max(extinction, 1e-8);

        luminance += scattering_integral;
        transmittance *= sample_transmittance;
      }

      if(intersects_ground) {
        vec3 hit_pos = ray.origin + t_max * ray.direction;
        if(dot(ray.origin, world_sun_dir) > 0.0) {
          Ray hit_ray;
          hit_ray.origin = hit_pos;
          hit_ray.direction = world_sun_dir;
          luminance += max0(transmittance * earth_albedo * texture(sun_transmittance_lut_tex, parameterise_sun_transmittance(hit_ray)).rgb);
        }
      }

      psi_ms += luminance_factor * inverse_samples;
      total_luminance += luminance * inverse_samples;
    }
  }

  vec3 psi = total_luminance;
  if(any(isnan(psi))){
    psi = vec3(1.0);
  } else {
    psi = vec3(0.0);
  }

  imageStore(multiple_scattering_lut, texel_coord, vec4(psi * 1000.0, 1.0));
}