#version 460 compatibility

in vec2 uv;

layout(location = 0) out float caustics;

void main() {
  caustics = uv.x;
}
