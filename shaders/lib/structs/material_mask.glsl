#ifndef MATERIAL_MASK_GLSL
#define MATERIAL_MASK_GLSL

struct MaterialMask {
  bool is_fluid;
  bool is_full_block;
  bool is_emissive;
  bool parallax_shadow; // TODO: not this
};

MaterialMask build_material_mask(uint block_id) {
  MaterialMask mask;

  mask.is_fluid = iris_hasFluid(block_id);
  mask.is_full_block = iris_isFullBlock(block_id);
  mask.is_emissive = iris_getEmission(block_id) > 0;

  return mask;
}

float encode_material_mask(MaterialMask mask) {
  int encoded_mask = 0;

  encoded_mask = encoded_mask | (mask.is_fluid ? 1 : 0);
  encoded_mask = encoded_mask | (mask.is_full_block ? 1 << 1 : 0);
  encoded_mask = encoded_mask | (mask.is_emissive ? 1 << 2 : 0);
  encoded_mask = encoded_mask | (mask.parallax_shadow ? 1 << 3 : 0);

  return encoded_mask / 255.0;
}

MaterialMask decode_material_mask(float encoded_mask) {
  MaterialMask mask;
  int int_mask = int(floor(encoded_mask * 255.0 + 0.5));

  mask.is_fluid = (int_mask & 1) == 1;
  mask.is_full_block = (int_mask & (1 << 1)) == 1;
  mask.is_emissive = (int_mask & (1 << 2)) == 1;
  mask.parallax_shadow = (int_mask & (1 << 3)) == 1;

  return mask;
}

#endif // MATERIAL_MASK_GLSL
