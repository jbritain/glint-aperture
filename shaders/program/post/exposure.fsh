#version 460 core

#include "/lib/common.glsl"
#include "/lib/buffers/camera_data.glsl"

in vec2 uv;

uniform sampler2D scene_tex;

layout(location = 0) out vec3 color;

void main() {
  color = texture(scene_tex, uv).rgb * 0.01; //auto_exposure;

}
