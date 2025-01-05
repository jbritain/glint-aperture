#ifndef SPACE_CONVERSIONS_GLSL
#define SPACE_CONVERSIONS_GLSL

vec3 screenSpaceToViewSpace(vec3 screenPos) {
    vec4 homPos = playerProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
    return homPos.xyz / homPos.w;
}

float screenSpaceToViewSpace(float depth) {
	vec4 homPos = playerProjectionInverse * vec4(0.0, 0.0, depth * 2.0 - 1.0, 1.0);
	return homPos.z / homPos.w;
}

vec3 viewSpaceToScreenSpace(vec3 viewPos) {
	vec4 clipPos = playerProjection * vec4(viewPos, 1.0);
	return (clipPos.xyz / clipPos.w) * 0.5 + 0.5;
}

float viewSpaceToScreenSpace(float depth) {
	vec4 clipPos = playerProjection * vec4(0.0, 0.0, depth, 1.0);
	return (clipPos.z / clipPos.w) * 0.5 + 0.5;
}

#endif
