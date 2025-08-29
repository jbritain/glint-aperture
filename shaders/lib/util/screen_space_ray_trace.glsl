#ifndef SCREEN_SPACE_RAY_TRACE_GLSL
#define SCREEN_SPACE_RAY_TRACE_GLSL

#define BINARY_REFINEMENTS 6
#define BINARY_REDUCTION 0.5

const float hand_depth = 0.0; //MC_HAND_DEPTH * 0.5 + 0.5;

float get_depth(vec2 pos, sampler2D depth_sampler, int lod) {
  return texelFetch(depth_sampler, ivec2(pos * ap.game.screenSize), lod).r;
}

void binary_search(
  inout vec3 ray_pos,
  vec3 ray_dir,
  sampler2D depth_sampler,
  int lod
) {
  for (int i = 0; i < BINARY_REFINEMENTS; i++) {
    ray_dir *= BINARY_REDUCTION;
    float depth = get_depth(ray_pos.xy, depth_sampler, lod);
    float intersect = sign(depth - ray_pos.z);

    ray_pos += intersect * ray_dir;
  }
}

// traces through screen space to find intersection point
// thanks, belmu!!
// https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
bool ray_intersects(
  vec3 view_origin,
  vec3 view_dir,
  int max_steps,
  float jitter,
  out vec3 ray_pos,
  sampler2D depth_sampler,
  int lod
) {
  if (view_dir.z > 0.0 && view_dir.z >= -view_origin.z) {
    return false;
  }

  ray_pos = view_space_to_screen_space(view_origin);

  vec3 ray_dir = normalize(
    view_space_to_screen_space(view_origin + view_dir) - ray_pos
  );

  float ray_length = min_vec2(
    abs(sign(ray_dir.xy) - ray_pos.xy) / max(abs(ray_dir.xy), 1e-6)
  );
  float step_length = ray_length * rcp(float(max_steps));

  vec2 sampler_res = textureSize(depth_sampler, 0).xy;

  vec3 ray_step = ray_dir * step_length;
  ray_pos += ray_step * jitter + ray_dir * vec3(rcp(sampler_res), 0.0);

  float depth_lenience = max(abs(ray_step.z) * 3.0, 0.02 / pow2(view_origin.z));

  bool intersect = false;

  for (int i = 0; i < max_steps; ++i, ray_pos += ray_step) {
    if (saturate(ray_pos.xy) != ray_pos.xy) return false;

    float depth = get_depth(ray_pos.xy, depth_sampler, lod);
    if (depth == 1.0) return false;

    if (
      abs(depth_lenience - (ray_pos.z - depth)) < depth_lenience &&
      ray_pos.z > hand_depth
    ) {
      intersect = true;
      break;
    }
  }

  if (intersect) {
    binary_search(ray_pos, ray_step, depth_sampler, lod);
  }

  return intersect;
}
#endif // SCREEN_SPACE_RAY_TRACE_GLSL
