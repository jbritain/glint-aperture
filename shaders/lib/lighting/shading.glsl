#ifndef SHADING_GLSL
#define SHADING_GLSL

#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/screenSpaceReflections.glsl"
#include "/lib/buffers/sceneData.glsl"

vec3 generateConeVector(vec3 vector, vec2 xy, float angle) {
    xy.x *= radians(360.0);
    float cosAngle = cos(angle);
    xy.y = xy.y * (1.0 - cosAngle) + cosAngle;
    vec3 sphereCap = vec3(vec2(cos(xy.x), sin(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
    return rotate(sphereCap, vec3(0, 0, 1), vector);
}

vec3 getPointLight(vec3 playerPos, vec3 mappedNormal, vec3 faceNormal, Material material){
    vec3 light = vec3(0.0);

    vec2 noise = vec2(interleavedGradientNoise(floor(gl_FragCoord.xy), ap.time.frames * 2), interleavedGradientNoise(floor(gl_FragCoord.xy), ap.time.frames * 2 + 1));

    for(int i = 0; i < 64; i++){
        vec3 plVector = playerPos - ap.point.pos[i].xyz;
        float plDist = length(plVector);

        if(plDist > POINT_FAR_PLANE) continue;

        plVector = plDist * generateConeVector(normalize(plVector), noise, 0.05);

        const float bias = 0.05;
        float depth = (POINT_FAR_PLANE + POINT_NEAR_PLANE - 2.0 * POINT_NEAR_PLANE * POINT_FAR_PLANE / (maxVec3(abs(plVector)) - bias)) / (POINT_FAR_PLANE - POINT_NEAR_PLANE) * 0.5 + 0.5;
        float shadow = texture(pointLightFiltered, vec4(plVector, i), depth);

        light += iris_getLightColor(ap.point.block[i]).rgb * iris_getEmission(ap.point.block[i]) * rcp(plDist) * cookTorrancePoint(material, mappedNormal, faceNormal, playerPos, ap.point.pos[i].xyz) * shadow;
    }

    return light;
}

vec3 getShadedColor(Material material, vec3 mappedNormal, vec3 faceNormal, float skylight, vec3 blocklight, vec3 viewPos, out vec3 fresnel){
    vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

    float scatter;
    vec3 shadow = getShadowing(playerPos, faceNormal, vec2(skylight, 1.0), material, scatter);


    vec3 F;
    vec3 color = max0(cookTorrance(material, mappedNormal, faceNormal, viewPos, shadow, scatter, false, F) * sunlightColor);

    vec3 diffuse = 
        material.albedo * (
        skylightColor * pow3(skylight) * (material.ao * 0.5 + 0.5) +
        // pow(vec3(255, 152, 54), vec3(2.2)) * 1e-8 * max0(exp(-(1.0 - lightmap.x * 10.0))) +
        blocklight + 
        vec3(material.ao * 0.05)
        )
    ;

    vec3 specular = max0(getScreenSpaceReflections(fresnel, viewPos, material, mappedNormal, skylight));

    color += mix(diffuse, specular, clamp01(fresnel));

    #ifdef SHADOW_POINT_LIGHT
    color += getPointLight(playerPos, mat3(ap.camera.viewInv) * mappedNormal, mat3(ap.camera.viewInv) * faceNormal, material);
    #endif

    fresnel = mix(fresnel, F, F / (F + fresnel));

    #if !defined SSGI_ENABLE || defined FORWARD_LIGHTING
    color += material.emission * material.albedo * 16.0;
    #endif

    return color;
}

vec3 getShadedColor(Material material, vec3 mappedNormal, vec3 faceNormal, float skylight, float blocklight, vec3 viewPos, out vec3 fresnel){
    vec3 blocklightColor = pow(vec3(255, 152, 54), vec3(2.2)) * 1e-8 * max0(exp(-(1.0 - blocklight * 10.0)));
    return getShadedColor(material, mappedNormal, faceNormal, skylight, blocklightColor, viewPos, fresnel);
}
