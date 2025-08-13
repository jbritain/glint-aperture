#ifndef SSR_GLSL
#define SSR_GLSL

#include "/lib/util/screen_space_ray_trace.glsl"
#include "/lib/lighting/vndf.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

#define ROUGH_REFLECTION_SAMPLES 4
#define ROUGH_REFLECTION_STEPS 8
#define SMOOTH_REFLECTION_STEPS 32

vec4 ssr_sample(
  vec3 view_pos,
  vec3 view_dir,
  vec3 normal,
  float sky_factor,
  int samples,
  float jitter,
  sampler2D depth_sampler,
  sampler2D color_sampler,
  bool reproject
) {
  vec3 ray_dir = reflect(view_dir, normal);

  float NoV = dot(normal, -view_dir);

  vec3 screen_ray_pos;
  if (
    ray_intersects(view_pos, ray_dir, 32, jitter, screen_ray_pos, depth_sampler)
  ) {
    vec3 previous_pos;
    if (reproject) {
      previous_pos = screen_space_to_view_space(screen_ray_pos);
      previous_pos = (ap.camera.viewInv * vec4(previous_pos, 1.0)).xyz;
      previous_pos += ap.camera.pos;
      previous_pos -= ap.temporal.pos;
      previous_pos = (ap.temporal.view * vec4(previous_pos, 1.0)).xyz;
      previous_pos = previous_view_space_to_previous_screen_space(previous_pos);
    }

    return vec4(
      texture(
        color_sampler,
        reproject
          ? previous_pos.xy
          : screen_ray_pos.xy
      ).rgb,
      NoV
    );
  }

  return vec4(
    get_sky(normalize(mat3(ap.camera.viewInv) * ray_dir), false) * sky_factor,
    NoV
  );
}

vec4 compute_rough_reflections(
  vec3 view_pos,
  vec3 view_dir,
  float roughness,
  vec3 normal,
  float sky_factor,
  sampler2D depth_sampler,
  sampler2D color_sampler,
  bool reproject
) {
  mat3 tbn = generate_tbn(normal);

  vec3 tangent_view_dir = normalize(-view_dir * tbn);

  vec4 average_ssr;

  vec4 noise;
  for (int i = 0; i < ROUGH_REFLECTION_SAMPLES; i++) {
    noise = blue_noise(
      floor(gl_FragCoord.xy),
      i + ap.time.frames * ROUGH_REFLECTION_SAMPLES
    );

    vec3 vndf_normal =
      tbn * sample_vndf_ggx(tangent_view_dir, vec2(roughness), noise.xy);

    if (dot(reflect(normalize(view_pos), vndf_normal), vndf_normal) < 0.0) {
      continue;
    }

    average_ssr += ssr_sample(
      view_pos,
      view_dir,
      vndf_normal,
      sky_factor,
      ROUGH_REFLECTION_STEPS,
      interleaved_gradient_noise(
        floor(gl_FragCoord.xy),
        i + ap.time.frames * ROUGH_REFLECTION_SAMPLES
      ),
      depth_sampler,
      color_sampler,
      reproject
    );
  }
  return average_ssr / float(ROUGH_REFLECTION_SAMPLES);
}

// the alpha channel stores the average NoV
// I don't store fresnel because it's expensive and I would need to pack it in a vec3 for metals
vec4 compute_screen_space_reflections(
  vec3 view_pos,
  float roughness,
  vec3 normal,
  float sky_factor,
  sampler2D depth_sampler,
  sampler2D color_sampler,
  bool reproject
) {
  vec3 view_dir = normalize(view_pos);
  if (roughness < 0.01) {
    return ssr_sample(
      view_pos,
      view_dir,
      normal,
      sky_factor,
      SMOOTH_REFLECTION_STEPS,
      interleaved_gradient_noise(floor(gl_FragCoord.xy), ap.time.frames),
      depth_sampler,
      color_sampler,
      reproject
    );
  } else if (roughness < 0.3) {
    return compute_rough_reflections(
      view_pos,
      view_dir,
      roughness,
      normal,
      sky_factor,
      depth_sampler,
      color_sampler,
      reproject
    );
  } else {
    return vec4(vec3(0.0), 1.0);
  }
}

#endif // SSR_GLSL
