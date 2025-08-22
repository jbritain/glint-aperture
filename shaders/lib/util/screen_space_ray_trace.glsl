#ifndef SCREEN_SPACE_RAY_TRACE_GLSL
#define SCREEN_SPACE_RAY_TRACE_GLSL

#include "/lib/util/space_conversions.glsl"

/*
McGuire & Mara (2014).
"Efficient GPU Screen-Space Ray Tracing"
https://jcgt.org/published/0003/04/04/paper.pdf
*/

const float hand_depth = 0.56; //MC_HAND_DEPTH * 0.5 + 0.5;

float get_depth(vec2 pos, sampler2D depth_sampler) {
  return texelFetch(depth_sampler, ivec2(pos * ap.game.screenSize), 0).r;
}

// traces through screen space to find intersection point

bool ray_intersects(
  vec3 view_origin,
  vec3 view_dir,
  mat4 projection,
  sampler2D depth_sampler,
  float thickness,
  float stride,
  float jitter,
  const float max_steps,
  float max_distance,
  out vec3 hit_screen_pos,
  out vec3 hit_view_pos
) {
  // clip to near plane
  float ray_length =
    view_origin.z + view_dir.z * max_distance > ap.camera.near
      ? (ap.camera.near - view_origin.z) / view_origin.z
      : max_distance;
  vec3 view_end_pos = view_origin + view_dir * ray_length;
  vec2 hit_uv = vec2(-1, -1);

  // project to screen space
  vec4 h_0 = projection * vec4(view_origin, 1.0);
  vec4 h_1 = projection * vec4(view_end_pos, 1.0);
  float k_0 = 1.0 / h_0.w;
  float k_1 = 1.0 / h_1.w;

  vec3 q_0 = view_origin * k_0;
  vec3 q_1 = view_end_pos * k_1;

  // screen space endpoints
  vec2 p_0 = h_0.xy * k_0;
  vec2 p_1 = h_1.xy * k_1;

  p_1 += vec2(distance_squared(p_0, p_1) < 1e-4 ? 0.01 : 0.0);
  vec2 delta = p_1 - p_0;

  bool permute = false;
  if (abs(delta.x) < abs(delta.y)) {
    permute = true;
    delta = delta.yx;
    p_0 = p_0.yx;
    p_1 = p_1.yx;
  }

  float step_dir = sign(delta.x);
  float inv_dx = step_dir / delta.x;

  // track derivatives of d and q
  vec3 d_q = (q_1 - q_0) * inv_dx;
  float d_k = (k_1 - k_0) * inv_dx;
  vec2 d_p = vec2(step_dir, delta.y * inv_dx);

  d_p *= stride;
  d_q *= stride;
  d_k *= stride;
  p_0 += d_p * jitter;
  q_0 += d_q * jitter;
  k_0 += d_k * jitter;

  float prev_z_max_estimate = view_origin.z;
  float ray_z_max = prev_z_max_estimate;
  float ray_z_min = prev_z_max_estimate;
  float scene_z_max = ray_z_max + 1e4;

  // slide p from p_0 to p_1, (now-homogeneous) q from q_0 to q_1, and k from k_0 to k_1
  vec3 q = q_0;
  float k = k_0;
  float step_count = 0.0;
  float end = p_1.x * step_dir;
  for (
    vec2 p = p_0;
    p.x * step_dir <= end &&
    step_count < max_steps &&
    (ray_z_max < scene_z_max || ray_z_min > scene_z_max) &&
    scene_z_max != 1.0;
    // prettier-ignore
    p += d_p, q.z += d_q.z,  k += d_k,  step_count += 1.0
  ) {
    hit_uv = permute ? p.yx : p;

    ray_z_min = prev_z_max_estimate;
    ray_z_max = (d_q.z * 0.5 + q.z) / (d_k * 0.5 + k);
    prev_z_max_estimate = ray_z_max;
    if (ray_z_min > ray_z_max) {
      swap(ray_z_min, ray_z_max);
    }

    scene_z_max = screen_space_to_view_space(get_depth(hit_uv, depth_sampler));
  }

  q.xy += d_q.xy * step_count;
  hit_view_pos = q * (1.0 / k);

  hit_screen_pos = vec3(hit_uv, scene_z_max);

  // Matches the new loop condition:
  return ray_z_max >= scene_z_max - thickness && ray_z_min <= scene_z_max;
}
#endif // SCREEN_SPACE_RAY_TRACE_GLSL
