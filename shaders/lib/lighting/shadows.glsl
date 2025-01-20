#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/shadowSpace.glsl"

vec3 sampleShadow(vec3 shadowScreenPos, int cascade){
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
}

vec3 getShadowing(vec3 playerPos, vec3 faceNormal, vec2 lightmap, Material material, out float scatter){
    scatter = 0.0;

    float fakeShadow = clamp01(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y));
    float faceNoL = clamp01(dot(faceNormal, lightDir));
    float sampleRadius = 0.01;

    if(faceNoL < 1e-6 && material.sss < 1e-6){
        return vec3(1.0);
    }

    if(faceNoL <= 1e-6 && material.sss > 1e-6){
      scatter = max0(1.0 - faceNoL) * material.sss;
      sampleRadius *= (1.0 + 7.0 * material.sss);

      float VoL = dot(normalize(playerPos), worldSunDir);
      float phase1 = henyeyGreenstein(0.4, VoL) * 0.75;
      float phase2 = henyeyGreenstein(0.1, VoL) * 0.5;
      float phase3 = henyeyGreenstein(0.6, VoL);

      scatter *= max(max(phase1, phase2), phase3);
    }

    int cascade;
	vec3 shadowScreenPos = getShadowScreenPos(playerPos, mat3(playerModelViewInverse) * faceNormal, cascade);

	if(clamp01(shadowScreenPos.xy) != shadowScreenPos.xy){
        return vec3(fakeShadow);
    }

    float noise = interleavedGradientNoise(floor(gl_FragCoord.xy), frameCounter);

    float scatterSampleAngle = noise * 2 * PI;
    vec2 scatterSampleOffset = vec2(sin(scatterSampleAngle), cos(scatterSampleAngle)) * (sampleRadius / 4);
    float blockerDepthDifference = max0(shadowScreenPos.z - texture(shadowMap, vec3(shadowScreenPos.xy + scatterSampleOffset, cascade)).r);
    float blockerDistance = blockerDepthDifference * 256;
    scatter *= (1.0 - smoothstep(0.0, 4.0, blockerDistance));

    vec3 shadow = vec3(0.0);
    for(int i = 0; i < 4; i++){
        vec3 offset = vec3(vogelDiscSample(i, 4, noise), 0.0) * sampleRadius;
        shadow += sampleShadow(shadowScreenPos + offset, cascade);
    }

    shadow /= 4.0;

    return shadow;

}

#endif