#version 460 core

uniform sampler2D SAMPLE_BUFFER;

in vec2 uv;

layout(location = 0) out vec4 color;
void main() {
  color = texture(SAMPLE_BUFFER, uv);
}
