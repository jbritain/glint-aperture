#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/util/shadowSpace.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/water/waveNormals.glsl"

vec3 sampleShadow(vec3 shadowScreenPos, int cascade, vec3 playerPos){
    float transparentShadow = texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r;

    if(transparentShadow >= 1.0 - 1e-6){
        return vec3(transparentShadow);
    }

    float solidShadow = texture(solidShadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r;

    if(solidShadow <= 1e-6){
        return vec3(solidShadow);
    }

    vec4 shadowColorData = texture(shadowColorTex, vec3(shadowScreenPos.xy, cascade));

    ShadowMask mask = decodeShadowMask(texture(shadowMaskTex, vec3(shadowScreenPos.xy, cascade)).r);
    if(mask.water){
        float zRange = (-2.0 / ap.celestial.projection[cascade][2][2]);

        float translucentShadowDepth = texture(shadowMap, vec3(shadowScreenPos.xy, cascade)).r;

        float depthDifference = shadowScreenPos.z - translucentShadowDepth;
        float distanceThroughWater = zRange * max0(depthDifference);
        
        // vec3 oldPos = playerPos + worldLightDir * distanceThroughWater;

        // vec3 waveNormal = waveNormal(oldPos.xz + ap.camera.pos.xz, vec3(0.0, 1.0, 0.0), 1.0);
        // vec3 refracted = refract(worldLightDir, waveNormal, 1.0/1.33);

        // vec3 newPos = playerPos + refracted * distanceThroughWater;

        // float oldArea = length(dFdx(oldPos)) * length(dFdy(oldPos));
        // float newArea = length(dFdx(newPos)) * length(dFdy(newPos));

        // float caustics = oldArea / max(newArea, 1e-6);

        return exp(-distanceThroughWater * WATER_DENSITY * waterExtinction);
    }

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
	vec3 shadowScreenPos = getShadowScreenPos(playerPos, mat3(ap.camera.viewInv) * faceNormal, cascade);

	if(clamp01(shadowScreenPos.xy) != shadowScreenPos.xy){
        return vec3(fakeShadow);
    }

    float noise = interleavedGradientNoise(floor(gl_FragCoord.xy), ap.time.frames);

    float scatterSampleAngle = noise * 2 * PI;
    vec2 scatterSampleOffset = vec2(sin(scatterSampleAngle), cos(scatterSampleAngle)) * (sampleRadius / 8);
    float blockerDepthDifference = max0(shadowScreenPos.z - texture(shadowMap, vec3(shadowScreenPos.xy + scatterSampleOffset, cascade)).r);
    float blockerDistance = blockerDepthDifference * 256;
    scatter *= (1.0 - smoothstep(0.0, 4.0, blockerDistance));

    sampleRadius /= (cascade + 1);

    vec3 shadow = vec3(0.0);
    for(int i = 0; i < SHADOW_SAMPLES; i++){
        vec3 offset = vec3(vogelDiscSample(i, SHADOW_SAMPLES, noise), 0.0) * sampleRadius;
        shadow += sampleShadow(shadowScreenPos + offset, cascade, playerPos);
    }

    shadow /= SHADOW_SAMPLES;

    return shadow;

}

float fastDiffuse(vec3 playerPos, vec3 faceNormal, vec2 lightmap, Material material){
    float faceNoL = clamp01(dot(faceNormal, lightDir));

    int cascade;
	vec3 shadowScreenPos = getShadowScreenPos(playerPos, mat3(ap.camera.viewInv) * faceNormal, cascade);

    if(clamp01(shadowScreenPos.xy) != shadowScreenPos.xy){
        return clamp01(smoothstep(13.5 / 15.0, 14.5 / 15.0, lightmap.y)) * faceNoL;
    }

    return texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r * faceNoL;
}

#endif
