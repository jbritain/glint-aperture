#ifndef SPACE_CONVERSIONS_GLSL
#define SPACE_CONVERSIONS_GLSL

vec3 screenSpaceToViewSpace(vec3 screenPos) {
	vec4 homPos = ap.camera.projectionInv * vec4(screenPos * 2.0 - 1.0, 1.0);
	return homPos.xyz / homPos.w;
}

float screenSpaceToViewSpace(float depth) {
	vec4 homPos = ap.camera.projectionInv * vec4(0.0, 0.0, depth * 2.0 - 1.0, 1.0);
	return homPos.z / homPos.w;
}

vec3 previousScreenSpaceToPreviousViewSpace(vec3 previousScreenPos) {
	vec4 homPos = ap.temporal.projectionInv * vec4(previousScreenPos * 2.0 - 1.0, 1.0);
	return homPos.xyz / homPos.w;
}

vec3 viewSpaceToScreenSpace(vec3 viewPos) {
	vec4 clipPos = ap.camera.projection * vec4(viewPos, 1.0);
	return (clipPos.xyz / clipPos.w) * 0.5 + 0.5;
}

float viewSpaceToScreenSpace(float depth) {
	vec4 clipPos = ap.camera.projection * vec4(0.0, 0.0, depth, 1.0);
	return (clipPos.z / clipPos.w) * 0.5 + 0.5;
}

vec3 previousViewSpaceToPreviousScreenSpace(vec3 previousViewPos){
	vec4 clipPos = ap.temporal.projection * vec4(previousViewPos, 1.0);
	return (clipPos.xyz / clipPos.w) * 0.5 + 0.5;
}

#endif
