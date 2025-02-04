#ifndef GBUFFER_DATA_GLSL
#define GBUFFER_DATA_GLSL

#include "/lib/util/packing.glsl"

struct GbufferData {
  Material material;
  MaterialMask materialMask;
  vec3 faceNormal;
  vec2 lightmap;
  vec3 mappedNormal;
};

void encodeGbufferData(out vec4 data1, out vec4 data2, in GbufferData data, vec4 specularData){
  vec3 gammaCorrectedAlbedo = pow(data.material.albedo, vec3(rcp(2.2)));

  data1.x = pack2x8F(gammaCorrectedAlbedo.r, gammaCorrectedAlbedo.g);
  data1.y = pack2x8F(gammaCorrectedAlbedo.b, encodeMaterialMask(data.materialMask));
  data1.z = pack2x8F(encodeNormal(mat3(ap.camera.viewInv) * data.faceNormal));
  data1.w = pack2x8F(data.lightmap);

  data2.x = pack2x8F(encodeNormal(mat3(ap.camera.viewInv) * data.mappedNormal));
  data2.y = pack2x8F(specularData.xy);
  data2.z = pack2x8F(specularData.zw);
  data2.w = data.material.ao;
}

void decodeGbufferData(in vec4 data1, in vec4 data2, out GbufferData data){
  vec2 decode1x = unpack2x8F(data1.x);
  vec2 decode1y = unpack2x8F(data1.y);
  vec2 decode1z = unpack2x8F(data1.z);
  vec2 decode1w = unpack2x8F(data1.w);

  vec2 decode2x = unpack2x8F(data2.x);
  vec2 decode2y = unpack2x8F(data2.y);
  vec2 decode2z = unpack2x8F(data2.z);
  // vec2 decode2w = unpack2x8F(data2.w);

  data.material = materialFromSpecularMap(vec3(decode1x.x, decode1x.y, decode1y.x), vec4(decode2y, decode2z), data2.w);

  data.material.albedo = pow(data.material.albedo, vec3(2.2));

  data.materialMask = decodeMaterialMask(decode1y.y);

  data.faceNormal = mat3(ap.camera.view) * decodeNormal(decode1z);
  data.lightmap = decode1w;

  data.mappedNormal = mat3(ap.camera.view) * decodeNormal(decode2x);
}

#endif // GBUFFER_DATA_GLSL
