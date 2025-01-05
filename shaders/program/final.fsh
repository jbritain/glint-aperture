#version 460 core

uniform sampler2D sceneTex;

#include "/lib/common.glsl"

in vec2 uv;
out vec4 fragColor;

vec3 hejlBurgessTonemap(vec3 v){
    v /= 2.0;
    vec3 x = max0(v - 0.004);
    return (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
}

void main() {
	fragColor = texture(sceneTex, uv);

	fragColor.rgb *= 0.2;
	fragColor.rgb = hejlBurgessTonemap(fragColor.rgb);
}
