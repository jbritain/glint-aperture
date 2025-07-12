#ifndef GBUFFER_GLSL
#define GBUFFER_GLSL

#include "/lib/common.glsl"
#include "/lib/util/encoding.glsl"

// enums for metal IDs
#define NO_METAL 0
#define IRON 1
#define GOLD 2
#define ALUMINIUM 3
#define CHROME 4
#define COPPER 5
#define LEAD 6
#define PLATINUM 7
#define SILVER 8
#define OTHER_METAL 9

vec3 get_metal_f0(uint metal_id, vec3 albedo) {
  switch (metal_id) {
    case IRON:
      return vec3(0.78, 0.77, 0.74);
    case GOLD:
      return vec3(1.0, 0.9, 0.61);
    case ALUMINIUM:
      return vec3(1.0, 0.98, 1.0);
    case CHROME:
      return vec3(0.77, 0.8, 0.79);
    case COPPER:
      return vec3(1.0, 0.89, 0.73);
    case LEAD:
      return vec3(0.79, 0.87, 0.85);
    case PLATINUM:
      return vec3(0.92, 0.9, 0.83);
    case SILVER:
      return vec3(1.0, 1.0, 0.91);
  }
  return albedo;
}

vec3 get_metal_f82(uint metal_id, vec3 albedo) {
  switch (metal_id) {
    case IRON:
      return vec3(0.74, 0.76, 0.76);
    case GOLD:
      return vec3(1.0, 0.93, 0.73);
    case ALUMINIUM:
      return vec3(0.96, 0.97, 0.98);
    case CHROME:
      return vec3(0.74, 0.79, 0.78);
    case COPPER:
      return vec3(1.0, 0.9, 0.8);
    case LEAD:
      return vec3(0.83, 0.8, 0.83);
    case PLATINUM:
      return vec3(0.89, 0.87, 0.81);
    case SILVER:
      return vec3(1.0, 1.0, 0.95);
  }
  return albedo;
}

// this is only used for encoding purposes
struct Gbuffer {
  vec3 geometry_normal;
  vec3 texture_normal;
  vec2 lightmap;
  vec3 albedo;
  vec4 specular_map;
  float material_ao;
};

void encode_gbuffer(out vec4 data_1, out vec4 data_2, Gbuffer gbuffer) {
  vec3 gamma_corrected_albedo = pow(gbuffer.albedo, vec3(rcp(2.2)));

  data_1.x = pack2x8F(gamma_corrected_albedo.r, gamma_corrected_albedo.g);
  data_1.y = pack2x8F(gamma_corrected_albedo.b, gbuffer.material_ao);
  data_1.z = pack2x8F(
    encode_unit_vector(mat3(ap.camera.viewInv) * gbuffer.geometry_normal)
  );
  data_1.w = pack2x8F(gbuffer.lightmap);

  data_2.x = pack2x8F(
    encode_unit_vector(mat3(ap.camera.viewInv) * gbuffer.texture_normal)
  );
  data_2.y = pack2x8F(gbuffer.specular_map.rg);
  data_2.z = pack2x8F(gbuffer.specular_map.ba);
  data_2.w = 0.0;
}

// not sure I will ever use this but it's here for posterity
Gbuffer decode_gbuffer(vec4 data_1, vec4 data_2) {
  Gbuffer gbuffer;

  vec2 decode_1x = unpack2x8F(data_1.x);
  vec2 decode_1y = unpack2x8F(data_1.y);
  vec2 decode_1z = unpack2x8F(data_1.z);
  vec2 decode_1w = unpack2x8F(data_1.w);

  vec2 decode_2x = unpack2x8F(data_2.x);
  vec2 decode_2y = unpack2x8F(data_2.y);
  vec2 decode_2z = unpack2x8F(data_2.z);
  // vec2 decode2w = unpack2x8F(data_2.w);

  gbuffer.albedo = pow(vec3(decode_1x.x, decode_1x.y, decode_1y.x), vec3(2.2));
  gbuffer.material_ao = decode_1y.y;

  gbuffer.geometry_normal =
    mat3(ap.camera.view) * decode_unit_vector(decode_1z);
  gbuffer.texture_normal = mat3(ap.camera.view) * decode_unit_vector(decode_2x);
  gbuffer.lightmap = decode_1w;

  gbuffer.specular_map = vec4(decode_2y, decode_2z);

  return gbuffer;
}

// and then this is what we use everywhere else
struct Material {
  vec3 geometry_normal;
  vec3 texture_normal;
  vec2 lightmap;
  vec3 albedo;
  uint metal_id;
  float f0;
  float roughness;
  float porosity;
  float subsurface;
  float ambient_occlusion;
  float emission;
};

Material decode_material_from_gbuffer(vec4 data_1, vec4 data_2) {
  vec2 decode_1x = unpack2x8F(data_1.x);
  vec2 decode_1y = unpack2x8F(data_1.y);
  vec2 decode_1z = unpack2x8F(data_1.z);
  vec2 decode_1w = unpack2x8F(data_1.w);

  vec2 decode_2x = unpack2x8F(data_2.x);
  vec2 decode_2y = unpack2x8F(data_2.y);
  vec2 decode_2z = unpack2x8F(data_2.z);
  // vec2 decode2w = unpack2x8F(data_2.w);

  Material material;

  material.albedo = pow(vec3(decode_1x.x, decode_1x.y, decode_1y.x), vec3(2.2));
  material.ambient_occlusion = decode_1y.y;

  material.geometry_normal =
    mat3(ap.camera.view) * decode_unit_vector(decode_1z);
  material.texture_normal =
    mat3(ap.camera.view) * decode_unit_vector(decode_2x);
  material.lightmap = decode_1w;

  vec4 specular_map = vec4(decode_2y, decode_2z);

  material.roughness = pow2(1.0 - specular_map.r);
  material.f0 = specular_map.g;

  material.metal_id = uint(specular_map.g * 255 + 0.5) - 229;
  if (material.metal_id != NO_METAL) {
    material.f0 = -1.0;
  }

  if (specular_map.b <= 0.25) {
    material.porosity = specular_map.b * 4.0;
    material.subsurface = 0.0;
  } else {
    material.porosity = (1.0 - specular_map.r) * specular_map.g; // fall back to using roughness and base reflectance for porosity
    material.subsurface = (specular_map.b - 0.25) * 4.0 / 3.0;
  }

  return material;
}

#endif
