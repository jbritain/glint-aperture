#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/atmospherics/atmosphere.glsl"

uniform sampler2D sky_view_lut_tex;
uniform sampler2D sky_transmittance_lut_tex;

vec3 getValFromSkyLUT(vec3 ray_dir, int lod) {
  return vec3(0.0);
}

vec3 sun(vec3 ray_dir) {
  return vec3(0.0);
}

vec3 get_sky(vec3 color, vec3 ray_dir, bool include_sun) {
  Ray sky_ray;
  sky_ray.origin = vec3(0.0, ap.camera.pos.y + earth_radius, 0.0);
  sky_ray.direction = ray_dir;

  vec3 transmittance = texture(
    sky_transmittance_lut_tex,
    parameterise_sun_transmittance(sky_ray)
  ).xyz;

  vec3 luminance = texture(
    sky_view_lut_tex,
    parameterise_sky_view(sky_ray)
  ).rgb;

  if (include_sun && dot(ray_dir, world_light_dir) > cos(sun_angular_radius)) {
    luminance += 1.0;
  }

  return luminance * sun_radiance + color * transmittance;

}

vec3 get_sky(vec3 ray_dir, bool include_sun) {
  return get_sky(vec3(0.0), ray_dir, include_sun);
}

#endif // SKY_GLSL
