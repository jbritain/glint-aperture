/*
Space conversions by Jessie-LC
https://github.com/Jessie-LC/open-source-utility-code/
*/

#ifndef SPACE_CONVERSIONS_GLSL
#define SPACE_CONVERSIONS_GLSL

vec3 screenSpaceToViewSpace(vec3 screenPosition) {
	screenPosition = screenPosition * 2.0 - 1.0;

	vec3 viewPosition  = vec3(vec2(playerProjectionInverse[0].x, playerProjectionInverse[1].y) * screenPosition.xy + playerProjectionInverse[3].xy, playerProjectionInverse[3].z);

  viewPosition /= playerProjectionInverse[2].w * screenPosition.z + playerProjectionInverse[3].w;

	return viewPosition;
}

float screenSpaceToViewSpace(float depth) {
	depth = depth * 2.0 - 1.0;
	return playerProjectionInverse[3].z / (playerProjectionInverse[2].w * depth + playerProjectionInverse[3].w);
}

vec3 viewSpaceToScreenSpace(vec3 viewPosition) {
	vec3 screenPosition  = vec3(playerProjection[0].x, playerProjection[1].y, playerProjection[2].z) * viewPosition + playerProjection[3].xyz;
	     screenPosition /= -viewPosition.z;

	return screenPosition * 0.5 + 0.5;
}

float viewSpaceToScreenSpace(float depth) {
	return ((playerProjection[2].z * depth + playerProjection[3].z) / -depth) * 0.5 + 0.5;
}

#endif
