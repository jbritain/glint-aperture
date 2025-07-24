#version 460 core

/*
  https://www.activision.com/cdn/research/Practical_Real_Time_Strategies_for_Accurate_Indirect_Occlusion_NEW%20VERSION_COLOR.pdf

  Also massive thanks to sixthsurge for helping me to get this working
*/

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArray shadowMap;
uniform sampler2D diffuse_tex;

#include "/lib/common.glsl"
#include "/lib/util/space_conversions.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"

in vec2 uv;

uniform sampler2D gbuffer_tex_1;

uniform sampler2D mainDepthTex;

layout(location = 0) out vec4 global_illumination;

#define GTAO_SLICE_COUNT 8
#define GTAO_DIRECTION_SAMPLE_COUNT 8
#define GTAO_RADIUS 2.0

float get_horizon_angle(
  //vec2 ray_dir,
  vec3 view_slice_dir,
  vec3 viewer_dir,
  vec3 screen_pos,
  vec3 view_pos,
  float jitter,
  out vec3 radiance
) {
  float step_size = GTAO_RADIUS / float(GTAO_DIRECTION_SAMPLE_COUNT);
  vec2 ray_step = (view_space_to_screen_space(
    view_pos + view_slice_dir * step_size
  ) -
    screen_pos).xy;

  vec2 ray_pos = uv;
  ray_pos +=
    ray_step * (jitter + max_vec2(rcp(ap.game.screenSize)) / length(ray_step));

  float max_horizon_cos = -1.0;

  float radiance_weight = 0.0;
  radiance = vec3(0.0);

  for (int i = 0; i < GTAO_DIRECTION_SAMPLE_COUNT; i++) {
    vec3 sample_pos = screen_space_to_view_space(
      vec3(ray_pos, texture(mainDepthTex, ray_pos).r)
    );

    vec3 sample_vec = sample_pos - view_pos;
    vec3 sample_dir = normalize(sample_vec);

    float falloff = smoothstep(3.0, 4.0, length(sample_vec));

    float horizon_cos = mix(dot(sample_dir, viewer_dir), -1.0, falloff);
    radiance +=
      texture(diffuse_tex, ray_pos.xy).rgb *
      max0(horizon_cos - max_horizon_cos);

    horizon_cos = max(horizon_cos, max_horizon_cos);
    ray_pos += ray_step;
  }

  radiance /= PI;

  return acos(clamp(max_horizon_cos, -1.0, 1.0));
}

void main() {
  float depth = texture(mainDepthTex, uv).r;
  global_illumination = vec4(0.0);
  if (depth == 1.0) {
    return;
  }

  vec2 jitter = vec2(
    interleaved_gradient_noise(floor(gl_FragCoord.xy), ap.time.frames * 2),
    interleaved_gradient_noise(floor(gl_FragCoord.xy), ap.time.frames * 2 + 1)
  );

  Reduced_Gbuffer gbuffer = decode_reduced_gbuffer(texture(gbuffer_tex_1, uv));

  float visibility = 0.0;
  vec3 screen_pos = vec3(uv, depth);
  vec3 view_pos = screen_space_to_view_space(screen_pos);
  vec3 viewer_dir = normalize(-view_pos);
  vec3 normal = mat3(ap.camera.view) * gbuffer.geometry_normal;

  vec3 viewer_right = normalize(cross(vec3(0.0, 1.0, 0.0), viewer_dir));
  vec3 viewer_up = cross(viewer_dir, viewer_right);
  mat3 local_to_view = mat3(viewer_right, viewer_up, viewer_dir);

  for (int slice = 0; slice < GTAO_SLICE_COUNT; slice++) {
    float phi = float(slice + jitter.x) * PI / float(GTAO_SLICE_COUNT);
    vec2 omega = vec2(cos(phi), sin(phi));

    vec3 slice_dir = vec3(omega, 0.0);
    vec3 view_slice_dir = local_to_view * slice_dir;
    vec3 ortho_slice_dir = slice_dir - dot(slice_dir, viewer_dir) * viewer_dir;
    vec3 axis = cross(slice_dir, viewer_dir);
    vec3 projected_normal = normal - axis * dot(normal, axis);

    float sign_gamma = sign(dot(ortho_slice_dir, projected_normal));
    float cos_gamma = saturate(
      dot(projected_normal, viewer_dir) / length(projected_normal)
    );
    float gamma = sign_gamma * acos(cos_gamma);

    vec3 radiance_1;
    vec3 radiance_2;

    vec2 horizon_angles = vec2(
      get_horizon_angle(
        view_slice_dir,
        viewer_dir,
        screen_pos,
        view_pos,
        jitter.y,
        radiance_1
      ),
      get_horizon_angle(
        -view_slice_dir,
        viewer_dir,
        screen_pos,
        view_pos,
        jitter.y,
        radiance_2
      )
    );

    vec3 radiance = (radiance_1 + radiance_2) / 2.0;

    horizon_angles =
      gamma + clamp(vec2(1.0, -1.0) * horizon_angles - gamma, -PI / 2, PI / 2);
    vec2 integr =
      cos_gamma +
      2.0 * horizon_angles * sin(gamma) -
      cos(2.0 * horizon_angles - gamma);

    global_illumination += vec4(radiance, 0.25 * (integr.x + integr.y));
  }

  global_illumination /= float(GTAO_SLICE_COUNT);

}
