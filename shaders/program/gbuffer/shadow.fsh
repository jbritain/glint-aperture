#version 450 core

in vec2 uv;
in vec4 color;

layout(location = 0) out vec4 albedo;

void iris_emitFragment() {
  vec2 mUV = uv;
  vec4 mColor = color;

  vec4 col = iris_sampleBaseTex(mUV) * mColor;

  if (iris_discardFragment(col)) discard;

  albedo = col;

  albedo.rgb = pow(albedo.rgb, vec3(2.2));
}