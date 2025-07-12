#ifndef INTERSECTIONS_GLSL
#define INTERSECTIONS_GLSL

// https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d
bool ray_sphere_intersection(
  Ray ray,
  vec3 sphere_centre,
  float sphere_radius,
  out vec3 intersection_point
) {
  float a = dot(ray.direction, ray.direction);
  vec3 sphere_centre_origin = ray.origin - sphere_centre;
  float b = 2.0 * dot(ray.direction, sphere_centre_origin);
  float c =
    dot(sphere_centre_origin, sphere_centre_origin) -
    sphere_radius * sphere_radius;
  if (b * b - 4.0 * a * c < 0.0) {
    return false;
  }
  float dist1 = (-b - sqrt(b * b - 4.0 * a * c)) / (2.0 * a);

  float dist2 = (-b + sqrt(b * b - 4.0 * a * c)) / (2.0 * a);

  if (dist1 < 0.0) dist1 = dist2;
  if (dist2 < 0.0) dist2 = dist1;

  if (dist1 < 0.0) return false;

  float dist = min(dist1, dist2);

  intersection_point = ray.origin + dist * ray.direction;
  return true;
}

#endif // INTERSECTIONS_GLSL
