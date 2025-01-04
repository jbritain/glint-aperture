#version 460 core

uniform sampler2D sceneTex;
uniform sampler2DArray shadowMap;
uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;

in vec2 uv;
out vec4 fragColor;

float luminance(vec3 color){
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 jodieReinhardTonemap(vec3 v){
	float l = luminance(v);
	vec3 tv = v / (1.0f + v);
	return mix(v / (1.0f + l), tv, tv);
}

void main() {
	fragColor = texture(sceneTex, uv);


	fragColor.rgb = jodieReinhardTonemap(fragColor.rgb);
	fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));

	fragColor = texture(multipleScatteringLUTTex, uv);
}
