#ifndef PARALLAX_GLSL
#define PARALLAX_GLSL

#define PARALLAX_DISTANCE 32.0
#define PARALLAX_DISTANCE_CURVE 0.8
#define PARALLAX_HEIGHT 0.25
#define PARALLAX_SAMPLES 32
#define PARALLAX_SHADOW_SAMPLES 16

float get_depth(vec2 uv, vec2 dx, vec2 dy) {
  return 1.0 - iris_sampleNormalMapGrad(uv, dx, dy).a;
  // return 1.0 - iris_sampleNormalMap(uv).a;
}

vec2 local_to_atlas(vec2 uv, vec4 texture_bounds, vec2 single_tex_size) {
  // vec2 local_coord = 1.0 - abs(mod(uv, 2.0) - 1.0); // mirror the texture coordinate if it goes out of bounds instead of wrapping it
  vec2 local_coord = fract(uv); // wrap texture coordinate

  return local_coord * single_tex_size + texture_bounds.xy;
}

vec2 atlas_to_local(vec2 uv, vec4 texture_bounds, vec2 single_tex_size) {
  return (uv - texture_bounds.xy) / single_tex_size;
}

vec2 apply_parallax(
  vec2 uv,
  vec3 view_pos,
  mat3 tbn_matrix,
  out vec3 previous_pos,
  vec2 dx,
  vec2 dy,
  vec4 texture_bounds,
  vec2 single_tex_size,
  vec3 mid_block
) {
  float dist_fade = smoothstep(
    PARALLAX_DISTANCE * PARALLAX_DISTANCE_CURVE,
    PARALLAX_DISTANCE,
    length(view_pos)
  );

  if (dist_fade >= 1.0) {
    previous_pos = vec3(-1.0);
    return uv;
  }

  vec3 player_pos = (ap.camera.viewInv * vec4(view_pos, 1.0)).xyz;

  vec3 view_dir = normalize(-view_pos) * tbn_matrix;

  float current_depth = get_depth(uv, dx, dy);

  const float layer_depth = rcp(PARALLAX_SAMPLES * (1.0 - dist_fade)); // depth per layer

  vec3 ray_step =
    vec3(
      view_dir.xy * rcp(-view_dir.z) * PARALLAX_HEIGHT * (1.0 - dist_fade),
      1.0
    ) *
    layer_depth;
  vec3 pos = vec3(atlas_to_local(uv, texture_bounds, single_tex_size), 0.0);
  vec3 start_pos = pos;

  float depth = get_depth(uv, dx, dy);
  if (depth < rcp(255.0)) {
    previous_pos = pos;
    return uv;
  }

  // pos += ray_step * jitter;

  depth = get_depth(
    local_to_atlas(pos.xy, texture_bounds, single_tex_size),
    dx,
    dy
  );

  while (depth - pos.z > rcp(255.0)) {
    previous_pos = pos;
    depth = get_depth(
      local_to_atlas(pos.xy, texture_bounds, single_tex_size),
      dx,
      dy
    );
    pos += ray_step;
  }

  pos = previous_pos;
  depth = get_depth(
    local_to_atlas(pos.xy, texture_bounds, single_tex_size),
    dx,
    dy
  );

  // binary refinement
  for (int i = 0; i < 6; i++) {
    ray_step /= 2.0;

    pos += ray_step * (depth - pos.z > rcp(255.0) ? 1.0 : -1.0);
    depth = get_depth(
      local_to_atlas(pos.xy, texture_bounds, single_tex_size),
      dx,
      dy
    );

    if (depth - pos.z > rcp(255.0)) {
      previous_pos = pos;
    }
  }

  return local_to_atlas(
    previous_pos.xy + ray_step.xy,
    texture_bounds,
    single_tex_size
  );
}

float parallax_shadow(
  vec3 pos,
  vec3 view_pos,
  mat3 tbn_matrix,
  vec2 dx,
  vec2 dy,
  float jitter
) {
  float dist_fade = smoothstep(
    PARALLAX_DISTANCE_CURVE * PARALLAX_DISTANCE,
    PARALLAX_DISTANCE,
    length(view_pos)
  );
  if (dist_fade >= 1.0) {
    return 1.0;
  }

  float NoL = saturate(dot(tbn_matrix[2], light_dir));
  if (NoL <= 0.0) {
    return dist_fade;
  }

  vec3 tangent_light_dir = normalize(light_dir * tbn_matrix);

  vec3 ray_step =
    vec3(light_dir.xy * 0.25 / tangent_light_dir.z, -1.0) *
    pos.z *
    (1.0 / PARALLAX_SHADOW_SAMPLES);

  pos += ray_step;

  if (get_depth(pos.xy, dx, dy) < pos.z) return dist_fade;

  pos += ray_step * jitter;

  for (int i = 0; i < PARALLAX_SHADOW_SAMPLES; i++, pos += ray_step) {
    if (get_depth(pos.xy, dx, dy) < pos.z) return dist_fade;
  }

  return 1.0;
}

#endif
