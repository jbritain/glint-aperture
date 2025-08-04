#ifndef POINT_LIGHTS_GLSL
#define POINT_LIGHTS_GLSL

#include "/lib/lighting/brdf.glsl"
#include "/lib/common.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/misc/light_lists.glsl"
#include "/lib/buffers/light_lists.glsl"

vec3 sample_point_light(
  uint index,
  vec3 player_pos,
  vec3 fresnel,
  Material material,
  vec2 jitter
) {
  ap_PointLight light = iris_getPointLight(index);

  vec3 sample_dir = normalize(light.pos - player_pos);

  float sample_distance = distance(player_pos, light.pos);

  // sample_dir = generate_cone_vector(
  //   sample_dir,
  //   jitter,
  //   atan(0.5, sample_distance)
  // );

  float light_dot = dot(sample_dir, material.texture_normal);

  // player_pos =
  //   light.pos -
  //   sample_dir *
  //     sample_distance *
  //     (1.0 - material.subsurface_scattering * 0.95 * float(light_dot < 0.0));

  float sample_depth = max_vec3(abs(light.pos - player_pos));



  float ndc_depth =
    (ap.point.farPlane +
      ap.point.nearPlane -
      2.0 * ap.point.nearPlane * ap.point.farPlane / sample_depth) /
    (ap.point.farPlane - ap.point.nearPlane);

  float shadow = texture(
    pointLightFiltered,
    vec4(-sample_dir, index),
    ndc_depth * 0.5 + 0.5
  );

  vec3 lighting =
    iris_getLightColor(light.block).rgb *
    (iris_getEmission(light.block) / 15.0) *
    EMISSION_STRENGTH *
    mix(
      material.albedo *
        saturate(light_dot) *
        float(material.metal_id == NO_METAL),
      brdf_specular(material, sample_dir, -normalize(player_pos)),
      fresnel
    ) *
    shadow;

  return lighting;
}

vec3 sample_all_point_lights(vec3 player_pos, Material material) {
  vec3 fresnel = schlick(
    material,
    dot(material.texture_normal, -normalize(player_pos))
  );
  vec2 jitter = blue_noise(floor(gl_FragCoord.xy), ap.time.frames).xy;
  vec3 light = vec3(0.0);

  uint bin = map_light_list_index(player_pos);

  for (int i = 0; i < light_lists[bin].final_light_count; i++) {
    light += sample_point_light(
      light_lists[bin].light_indeces[i],
      player_pos + 0.16 * material.geometry_normal,
      fresnel,
      material,
      jitter
    );
  }
  return light;
}

#endif // POINT_LIGHTS_GLSL
