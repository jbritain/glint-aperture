#version 460 core

layout(location = 0) out vec4 fragColor;

in vec2 uv;
in vec4 color;

void iris_emitFragment() {
  fragColor = iris_sampleBaseTex(uv) * color;

  if (iris_discardFragment(fragColor)) discard;
}
