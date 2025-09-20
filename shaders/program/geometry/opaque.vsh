#version 460 core

#include "/lib/common.glsl"

out vec2 uv;
out vec4 color;
out vec2 lightmap;
out vec3 view_pos;
flat out uint block_id;

out vec4 texture_bounds;
out vec2 texture_size;
out vec3 mid_block;

out mat3 tbn_matrix;

void iris_emitVertex(inout VertexData data) {
  data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

void iris_sendParameters(VertexData data) {
  uv = data.uv;
  lightmap = linearstep(vec2(0.5 / 15.0), vec2(14.5 / 15.0), data.light);

  color = vec4(
    mix(data.overlayColor.rgb, data.color.rgb, data.overlayColor.a),
    data.color.a
  );

  tbn_matrix[2] = normalize(mat3(iris_modelViewMatrix) * data.normal);
  tbn_matrix[0] = normalize(mat3(iris_modelViewMatrix) * data.tangent.xyz);
  tbn_matrix[1] = normalize(
    cross(tbn_matrix[0], tbn_matrix[2]) * data.tangent.w
  );

  view_pos = (iris_modelViewMatrix * data.modelPos).xyz;

  texture_bounds.xy = iris_getTexture(data.textureId).minCoord;
  texture_bounds.zw = iris_getTexture(data.textureId).maxCoord;

  texture_size = texture_bounds.zw - texture_bounds.xy;

  block_id = data.blockId;

  mid_block = data.midBlock;
}
