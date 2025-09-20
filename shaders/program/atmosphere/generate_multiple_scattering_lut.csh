/*
    Hillaire, S. (2020). A Scalable and Production Ready Sky and Atmosphere Rendering Technique.  https://sebh.github.io/publications/egsr2020.pdf
    Also based on code from 'Production Sky Rendering' by Andrew Helmer. https://www.shadertoy.com/view/slSXRW
*/

#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

#include "/lib/common.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/util/intersections.glsl"
#include "/lib/util/misc.glsl"



layout(rgba16f) uniform image2D multiple_scattering_lut;

void main() {
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(multiple_scattering_lut);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;

  Ray ray = un_parameterise_multiple_scattering(uv);

  #define MULTIPLE_SCATTERING_STEPS 20.0
  #define MULTIPLE_SCATTERING_SQRT_SAMPLES 8u

  vec3 total_luminance = vec3(0.0);
  vec3 psi_ms = vec3(0.0);

  float inverse_samples = 1.0 / pow2(float(MULTIPLE_SCATTERING_SQRT_SAMPLES));
  for (int i = 0; i < MULTIPLE_SCATTERING_SQRT_SAMPLES; i++) {
    for (int j = 0; j < MULTIPLE_SCATTERING_SQRT_SAMPLES; j++) {
      float theta =
        PI * (float(i) + 0.5) / float(MULTIPLE_SCATTERING_SQRT_SAMPLES);
      float phi = acos(
        clamp(
          1.0 -
            2.0 * (float(j) + 0.5) / float(MULTIPLE_SCATTERING_SQRT_SAMPLES),
          -1.0,
          1.0
        )
      );
      vec3 ray_dir = spherical_to_cartesian(vec2(theta, phi));

      Ray t_ray = Ray(ray.origin, ray_dir);
      bool intersects_ground = true;
      vec3 t_pos;
      ray_sphere_intersection(t_ray, vec3(0.0), earth_radius, t_pos);
      float t_max = distance(t_ray.origin, t_pos);
      if (t_max <= 0.0) {
        intersects_ground = false;
        ray_sphere_intersection(t_ray, vec3(0.0), atmosphere_radius, t_pos);
        t_max = distance(t_ray.origin, t_pos);
      }

      float cos_theta = dot(ray_dir, world_sun_dir);

      float mie_phase = mie_phase(cos_theta);
      float rayleigh_phase = rayleigh_phase(-cos_theta);

      vec3 luminance = vec3(0.0);
      vec3 luminance_factor = vec3(0.0);
      vec3 transmittance = vec3(1.0);
      float t = 0.0;
      for (
        float step_i = 0.0;
        step_i < MULTIPLE_SCATTERING_STEPS;
        step_i += 1.0
      ) {
        float new_t = (step_i + 0.3) / MULTIPLE_SCATTERING_STEPS * t_max;
        float dt = new_t - t;
        t = new_t;

        vec3 new_pos = ray.origin + t * ray_dir;
        float altitude = max0(length(new_pos) - earth_radius);

        float rayleigh_density = rayleigh_density(altitude);
        float mie_density = mie_density(altitude);
        float ozone_density = ozone_density(altitude);

        vec3 rayleigh_scattering = rayleigh_scattering_coeff * rayleigh_density;
        vec3 mie_scattering = mie_scattering_coeff * mie_density;

        vec3 extinction = rayleigh_scattering + mie_scattering;

        extinction += rayleigh_absorption_coeff * rayleigh_density;
        extinction += mie_absorption_coeff * mie_density;
        extinction += ozone_absorption_coeff * ozone_density;
        vec3 sample_transmittance = exp(-extinction * dt);

        vec3 scattering_no_phase = rayleigh_scattering + mie_scattering;
        vec3 scattering_f = scattering_no_phase; //(scattering_no_phase - scattering_no_phase * sample_transmittance) / max(extinction, 1e-6);
        luminance_factor += transmittance * scattering_f;

        vec3 sun_transmittance = texture(
          sun_transmittance_lut_tex,
          parameterise_sun_transmittance(Ray(new_pos, world_sun_dir))
        ).rgb;

        vec3 rayleigh_in_scattering = rayleigh_scattering * rayleigh_phase;
        vec3 mie_in_scattering = mie_scattering * mie_phase;
        vec3 in_scattering =
          (rayleigh_in_scattering + mie_in_scattering) *
          sun_transmittance *
          sun_irradiance;

        vec3 scattering_integral = in_scattering; // (in_scattering - in_scattering * sample_transmittance) / max(extinction, 1e-6);

        luminance += scattering_integral * transmittance;
        transmittance *= sample_transmittance;
      }

      if (intersects_ground) {
        vec3 hit_pos = ray.origin + t_max * ray_dir;
        if (dot(ray.origin, world_sun_dir) > 0.0) {
          hit_pos = normalize(hit_pos) * earth_radius;
          luminance +=
            transmittance *
            earth_albedo *
            texture(
              sun_transmittance_lut_tex,
              parameterise_sun_transmittance(Ray(hit_pos, world_sun_dir))
            ).rgb;
          ;
        }
      }

      psi_ms += luminance_factor * inverse_samples;
      total_luminance += luminance * inverse_samples;
    }
  }

  vec3 psi = total_luminance / (1.0 - psi_ms);

  imageStore(multiple_scattering_lut, texel_coord, vec4(psi * 10000.0, 1.0));
}
