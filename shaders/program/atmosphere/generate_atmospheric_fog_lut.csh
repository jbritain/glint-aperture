#version 460 core

#include "/lib/common.glsl"
#include "/lib/atmospherics/atmosphere.glsl"

layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(rgba16f) uniform image3D atmospheric_fog_lut;

uniform sampler2D sun_transmittance_lut_tex;

void main() {
  ivec3 texel_coord = ivec3(gl_GlobalInvocationID.xyz);
  ivec3 lut_res = imageSize(atmospheric_fog_lut);

  vec3 uv = clamp(texel_coord, vec3(0.0), lut_res - 1.0) / lut_res;


  vec3 ray_pos = vec3(0.0, ap.camera.pos.y + earth_radius + 64, 0.0);
  vec3 end_pos = (ap.camera.viewInv * vec4(screen_space_to_view_space(uv), 0.0)).xyz + vec3(0.0, ap.camera.pos.y + earth_radius + 64, 0.0);

  #define ATMOSPHERIC_FOG_STEPS 32u

  vec3 ray_step = (end_pos - ray_pos) / ATMOSPHERIC_FOG_STEPS;
  float step_length = length(ray_step);

  vec3 luminance = vec3(0.0);
  vec3 transmittance = vec3(1.0);

  float sun_cos_theta = dot(normalize(ray_step), world_sun_dir);
  float sun_rayleigh_phase = rayleigh_phase(-sun_cos_theta);
  float sun_mie_phase = mie_phase(sun_cos_theta);
  float moon_rayleigh_phase = rayleigh_phase(sun_cos_theta);
  float moon_mie_phase = mie_phase(-sun_cos_theta);

  ray_pos += ray_step * 0.5; // to centre us in each step

  for (uint i = 0u; i < ATMOSPHERIC_FOG_STEPS; i++) {
    float altitude = max0(length(ray_pos) - earth_radius);

    float rayleigh_density = rayleigh_density(altitude);
    float mie_density = mie_density(altitude);
    float ozone_density = ozone_density(altitude);

    vec3 rayleigh_scattering = rayleigh_scattering_coeff * rayleigh_density * 500.0;
    vec3 mie_scattering = mie_scattering_coeff * mie_density * 500.0;

    vec3 extinction = rayleigh_scattering + mie_scattering;

    extinction += rayleigh_absorption_coeff * rayleigh_density;
    extinction += mie_absorption_coeff * mie_density;
    extinction += ozone_absorption_coeff * ozone_density;
    vec3 sample_transmittance = exp(-extinction * step_length);

    // sun
    Ray sun_ray;
    sun_ray.origin = ray_pos;
    sun_ray.direction = world_sun_dir;
    vec3 sun_transmittance = texture(
      sun_transmittance_lut_tex,
      parameterise_sun_transmittance(sun_ray)
    ).rgb;

    vec3 scattering =
      (rayleigh_scattering * sun_rayleigh_phase + mie_scattering * sun_mie_phase) *
      sun_transmittance;

    vec3 scattering_integral =
      (scattering - scattering * sample_transmittance) / max(extinction, 1e-6);
    luminance += scattering_integral * transmittance * sun_irradiance;

    // moon
    sun_ray.direction = -world_sun_dir;
    sun_transmittance = texture(
      sun_transmittance_lut_tex,
      parameterise_sun_transmittance(sun_ray)
    ).rgb;

    scattering =
      (rayleigh_scattering * moon_rayleigh_phase + mie_scattering * moon_mie_phase) *
      sun_transmittance;

    scattering_integral =
      (scattering - scattering * sample_transmittance) / max(extinction, 1e-6);
    luminance += scattering_integral * transmittance * moon_irradiance;


    transmittance *= sample_transmittance;

    ray_pos += ray_step;
  }

  imageStore(atmospheric_fog_lut, texel_coord, vec4(luminance, (transmittance.x + transmittance.y + transmittance.z) / 3.0));

}