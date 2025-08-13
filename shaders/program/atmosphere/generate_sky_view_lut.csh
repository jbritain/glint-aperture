/*
    Hillaire, S. (2020). A Scalable and Production Ready Sky and Atmosphere Rendering Technique.  https://sebh.github.io/publications/egsr2020.pdf
*/

#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

#include "/lib/common.glsl"
#include "/lib/util/intersections.glsl"
#include "/lib/atmospherics/atmosphere.glsl"
#include "/lib/buffers/scene_data.glsl"

uniform sampler2D sun_transmittance_lut_tex;

layout(rgba16f) uniform image2D sky_view_lut;

void main() {
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(sky_view_lut);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;

  Ray ray = un_parameterise_sky_view(uv);

  // TODO: add handling for outside atmosphere because that is cool

  vec3 ray_pos = ray.origin;
  vec3 end_pos;

  bool intersects_earth = ray_sphere_intersection(
    ray,
    vec3(0.0),
    earth_radius,
    end_pos
  );
  vec3 earth_intersect_pos;

  if (!intersects_earth) {
    // if we did not hit the earth
    if (!ray_sphere_intersection(ray, vec3(0.0), atmosphere_radius, end_pos)) {
      // and we did not here the atmosphere
      imageStore(sky_view_lut, texel_coord, vec4(vec3(0.0), 1.0));
      return;
    }
  }

  #define SKY_VIEW_TRANSMITTANCE_STEPS 32u
  vec3 ray_step = (end_pos - ray_pos) / SKY_VIEW_TRANSMITTANCE_STEPS;
  float step_length = length(ray_step);

  vec3 luminance = vec3(0.0);
  vec3 transmittance = vec3(1.0);

  float sun_cos_theta = dot(ray.direction, world_sun_dir);
  float sun_rayleigh_phase = rayleigh_phase(-sun_cos_theta);
  float sun_mie_phase = mie_phase(sun_cos_theta);
  float moon_rayleigh_phase = rayleigh_phase(sun_cos_theta);
  float moon_mie_phase = mie_phase(-sun_cos_theta);

  ray_pos += ray_step * 0.5; // to centre us in each step

  for (uint i = 0u; i < SKY_VIEW_TRANSMITTANCE_STEPS; i++) {
    float altitude = max0(length(ray_pos) - earth_radius);

    float rayleigh_density = rayleigh_density(altitude);
    float mie_density = mie_density(altitude);
    float ozone_density = ozone_density(altitude);

    vec3 rayleigh_scattering = rayleigh_scattering_coeff * rayleigh_density;
    vec3 mie_scattering = mie_scattering_coeff * mie_density;

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

  if (intersects_earth) {
    Ray sun_ray;
    sun_ray.direction = world_sun_dir;
    sun_ray.origin = vec3(end_pos);

    vec3 sun_transmittance = texture(
      sun_transmittance_lut_tex,
      parameterise_sun_transmittance(sun_ray)
    ).rgb;

    luminance +=
      earth_albedo *
      sun_transmittance *
      transmittance *
      dot(world_light_dir, normalize(end_pos));
  }

  imageStore(sky_view_lut, texel_coord, vec4(luminance, 1.0));

  if (gl_GlobalInvocationID == ivec3(0)) {
    sunlight_color =
      texture(
        sun_transmittance_lut_tex,
        parameterise_sun_transmittance(
          Ray(
            vec3(0.0, ap.camera.pos.y + earth_radius + 64, 0.0),
            world_light_dir
          )
        )
      ).rgb *
      (light_dir == sun_dir ? sun_irradiance : moon_irradiance);
  }

}
