#ifndef HILLAIRE_GLSL
#define HILLAIRE_GLSL

/*
    Hillaire, S. (2020). A Scalable and Production Ready Sky and Atmosphere Rendering Technique.  https://sebh.github.io/publications/egsr2020.pdf
*/

const float sun_radius = 6.9634e8;
const float sun_distance = 1.496e11;
const float sun_angular_radius = sun_radius / sun_distance;
const vec3 sun_irradiance = vec3(1.0, 0.949, 0.937) * 126e3;
const vec3 sun_radiance =
  sun_irradiance / (TAU * (1.0 - cos(sun_angular_radius)));

const float earth_albedo = 0.25;

const float earth_radius = 6378e3;
const float atmosphere_height = 100e3;
const float atmosphere_radius = earth_radius + atmosphere_height;

const vec3 rayleigh_scattering_coeff = vec3(5.802, 13.558, 33.1) * 1e-6;
const vec3 mie_scattering_coeff = vec3(3.996) * 1e-6;

const vec3 rayleigh_absorption_coeff = vec3(0.0) * 1e-6;
const vec3 mie_absorption_coeff = vec3(4.4) * 1e-6;
const vec3 ozone_absorption_coeff = vec3(0.65, 1.881, 0.085) * 1e-6;

float rayleigh_phase(float cos_theta) {
  return 3.0 * (1.0 + pow2(cos_theta)) / 16.0 * PI;
}

float cornette_shanks_phase(float cos_theta, float g) {
  return 3.0 /
  (8.0 * PI) *
  ((1.0 - pow2(g)) * (1.0 + pow2(cos_theta))) /
  ((2.0 + pow2(g)) * pow(1.0 + pow2(g) - 2.0 * g * cos_theta, 3.0 / 2.0));
}

float mie_phase(float cos_theta) {
  return cornette_shanks_phase(cos_theta, 0.8);
}

float rayleigh_density(float altitude) {
  return max0(exp(-altitude / 8.0e3));
}

float mie_density(float altitude) {
  return max0(exp(-altitude / 1.2e3));
}

float ozone_density(float altitude) {
  return max0(1.0 - abs(altitude * 1e-3 - 25.0) / 15.0);
}

vec2 parameterise_sun_transmittance(Ray sun_vector) {
  vec2 uv;
  float altitude = sun_vector.origin.y - earth_radius;
  uv.y = altitude / atmosphere_height;

  float sun_cos_theta = dot(sun_vector.direction, vec3(0.0, 1.0, 0.0));
  uv.x = sun_cos_theta * 0.5 + 0.5;

  return saturate(uv);
}

// u corresponds to the angle of the sun in the sky relative to "up"
// v corresponds to the altitude of the position
Ray un_parameterise_sun_transmittance(vec2 uv) {
  Ray sun_vector;
  float altitude = earth_radius + atmosphere_height * uv.y;
  sun_vector.origin = vec3(0.0, altitude, 0.0);

  float sun_cos_theta = 2.0 * uv.x - 1.0;
  float sun_theta = acos(clamp(sun_cos_theta, -1.0, 1.0));
  sun_vector.direction = normalize(vec3(0.0, sun_cos_theta, sin(sun_theta)));

  return sun_vector;
}

// u is the rotation on the xz axis
// v is the rotation on the y axis
vec2 parameterise_sky_view(Ray ray) {
  vec2 uv;

  uv.x = asin(ray.direction.x) / TAU;

  float l = asin(ray.direction.y);
  uv.y = 0.5 + 0.5 * sign(l) * sqrt(abs(l) / (PI / 2));

  return saturate(uv);
}

Ray un_parameterise_sky_view(vec2 uv) {
  Ray ray;

  ray.direction.x = sin(uv.x * TAU);
  ray.direction.z = cos(uv.x * TAU);

  float l = uv.y * 2.0 - 1.0;
  l = sign(l) * pow2(l);
  ray.direction.y = sin(l) * (PI / 2);

  ray.origin = vec3(0.0, ap.camera.pos.y + earth_radius + 64, 0.0);

  return ray;
}

vec2 parameterise_multiple_scattering(Ray sun_vector) {
  vec2 uv;

  float sun_cos_theta = dot(sun_vector.direction, vec3(0.0, 1.0, 0.0));
  uv.x = sun_cos_theta * 0.5 + 0.5;

  float altitude = sun_vector.origin.y - earth_radius;
  uv.y = altitude / atmosphere_height;

  return saturate(uv);
}

Ray un_parameterise_multiple_scattering(vec2 uv) {
  Ray sun_vector;
  float altitude = earth_radius + atmosphere_height * uv.y;
  sun_vector.origin = vec3(0.0, altitude, 0.0);

  float sun_cos_theta = 2.0 * uv.x - 1.0;
  float sun_theta = acos(clamp(sun_cos_theta, -1.0, 1.0));
  sun_vector.direction = normalize(vec3(0.0, sun_cos_theta, sin(sun_theta)));

  return sun_vector;
}

#endif // HILLAIRE_GLSL
