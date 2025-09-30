#version 460 core

#include "/lib/common.glsl"
#include "/lib/util/screen_space_ray_trace.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/structs/gbuffer_material.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/reproject.glsl"

in vec2 uv;
uniform sampler2D diffuse_tex;
uniform sampler2D gbuffer_tex_1;
uniform sampler2D mainDepthTex;
uniform sampler2D previousSolidDepthTex;
uniform sampler2D global_illumination_tex;

layout(location = 0) out vec4 global_illumination;

#define SSGI_SAMPLES 4
#define SSGI_STEPS 6

void main() {
  float depth = texture(mainDepthTex, uv).r;
  vec3 view_pos = screen_space_to_view_space(vec3(uv, depth));

  global_illumination = vec4(0.0);
  if (depth == 1.0) {
    return;
  }

  Reduced_Gbuffer gbuffer = decode_reduced_gbuffer(texture(gbuffer_tex_1, uv));
  vec3 view_normal = mat3(ap.camera.view) * gbuffer.geometry_normal;

  mat3 tbn = generate_tbn(view_normal);

  for (int i = 0; i < SSGI_SAMPLES; i++) {
    vec3 sample_noise = blue_noise(
      floor(gl_FragCoord.xy),
      ap.time.frames,
      i
    ).xyz;

    float sin_theta = sqrt(1.0 - sample_noise.x);
    float phi = 2.0 * PI * sample_noise.y;

    vec3 sample_pos;

    vec3 sample_dir =
      tbn *
      vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, sqrt(sample_noise.x));

    bool intersect = ray_intersects(
      view_pos,
      sample_dir,
      SSGI_STEPS,
      sample_noise.x,
      sample_pos,
      mainDepthTex,
      0
    );

    if (intersect) {
      global_illumination.rgb += texture(diffuse_tex, sample_pos.xy).rgb;
    } else {
      global_illumination.a += 1.0;
    }
  }

  global_illumination /= float(SSGI_SAMPLES);

  vec3 previous_view_pos = reproject_view_to_previous_frame(view_pos);
  vec3 previous_screen_pos = previous_view_space_to_previous_screen_space(
    previous_view_pos
  );
  previous_screen_pos.z = texture(
    previousSolidDepthTex,
    previous_screen_pos.xy
  ).r;
  vec3 actual_previous_view_pos = previous_screen_space_to_previous_view_space(
    previous_screen_pos
  );

  // vec3 previous_normal = normalize(
  //   cross(
  //     normalize(dFdx(actual_previous_view_pos)),
  //     normalize(dFdy(actual_previous_view_pos))
  //   )
  // );

  if (
    distance(previous_view_pos, actual_previous_view_pos) < 0.1 &&
    previous_screen_pos.z != 1.0 &&
    saturate(previous_screen_pos.xy) == previous_screen_pos.xy
  ) {
    global_illumination = mix(
      global_illumination,
      texture(global_illumination_tex, previous_screen_pos.xy),
      0.95
    );
  }

  show(global_illumination.a);

}
