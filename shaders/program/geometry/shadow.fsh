#version 460 core

layout(location = 0) out vec4 fragColor;

in vec2 uv;

void iris_emitFragment() {
  fragColor = iris_sampleBaseTex(uv);

  if (iris_discardFragment(fragColor)) discard;
}
