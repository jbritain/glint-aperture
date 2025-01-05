#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/shadowSpace.glsl"

vec3 getShadowing(vec3 playerPos, vec3 faceNormal, vec2 lightmap, Material material, out float scatter){
    scatter = 0.0;
    float fakeShadow = clamp01(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y));

    int cascade;
	vec3 shadowScreenPos = getShadowScreenPos(playerPos, mat3(playerModelViewInverse) * faceNormal, cascade);

	if(clamp01(shadowScreenPos.xy) == shadowScreenPos.xy){
		return vec3(texture(shadowMap, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r);
	} else {
        return vec3(fakeShadow);
    }
}

#endif