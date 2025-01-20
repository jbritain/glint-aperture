#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/shadowSpace.glsl"

vec3 getShadowing(vec3 playerPos, vec3 faceNormal, vec2 lightmap, Material material, out float scatter){
    scatter = 0.0;
    float fakeShadow = clamp01(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y));

    int cascade;
	vec3 shadowScreenPos = getShadowScreenPos(playerPos, mat3(playerModelViewInverse) * faceNormal, cascade);

	if(clamp01(shadowScreenPos.xy) == shadowScreenPos.xy){
        float transparentShadow = texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r;

		if(transparentShadow >= 1.0 - 1e-6){
            return vec3(transparentShadow);
        }

        float solidShadow = texture(solidShadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r;

    	if(solidShadow <= 1e-6){
		    return vec3(solidShadow);
	    }

        vec4 shadowColorData = texture(shadowColorTex, vec3(shadowScreenPos.xy, cascade));
        vec3 shadowColor = pow(shadowColorData.rgb, vec3(2.2)) * (1.0 - shadowColorData.a);
	    return mix(shadowColor * solidShadow, vec3(1.0), transparentShadow);
	} else {
        return vec3(fakeShadow);
    }
}

#endif