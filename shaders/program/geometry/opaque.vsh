#version 460 core

out vec2 uv;
out vec4 color;
out vec2 lightmap;
out vec3 view_pos;

out mat3 tbn_matrix;

void iris_emitVertex(inout VertexData data) {
  data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

void iris_sendParameters(VertexData data) {
  uv = data.uv;
  lightmap = data.light;

  color = vec4(
    mix(data.overlayColor.rgb, data.color.rgb, data.overlayColor.a),
    data.color.a
  );

  tbn_matrix[2] = normalize(mat3(iris_modelViewMatrix) * data.normal.xyz);
  tbn_matrix[0] = normalize(mat3(iris_modelViewMatrix) * data.tangent.xyz);
  tbn_matrix[1] = normalize(
    cross(tbn_matrix[0], tbn_matrix[2]) * data.tangent.w
  );

  view_pos = (iris_modelViewMatrix * data.modelPos).xyz;
}
