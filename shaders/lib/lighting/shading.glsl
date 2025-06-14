#ifndef SHADING_GLSL
#define SHADING_GLSL

#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/lighting/screenSpaceReflections.glsl"
#include "/lib/buffers/sceneData.glsl"

vec3 getPointLight(vec3 playerPos, vec3 mappedNormal, vec3 faceNormal, Material material){
    vec3 light = vec3(0.0);
    for(int i = 0; i < 8; i++){
        vec3 plVector = playerPos - ap.point.pos[i].xyz;
        float plDist = length(plVector);
        if(plDist > 52) continue;
        
        float sampledReversedZ = texture(pointLight, vec4(normalize(plVector), i)).r;
        float closestDepth = 52 * 0.5 / (sampledReversedZ * (52 - 0.5) + 0.5);

        float bias = 0.0;
        float shadow = (plDist - bias > closestDepth) ? 0.0 : 1.0;

        light += iris_getLightColor(ap.point.block[i]).rgb * iris_getEmission(ap.point.block[i]) * rcp(plDist) * cookTorrancePoint(material, mappedNormal, faceNormal, playerPos, ap.point.pos[i].xyz) * shadow;
        // show(texture(pointLight, vec4(normalize(playerPos), 0)));
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
        // blocklight + 
        vec3(material.ao * 0.05)
        )
    ;

    vec3 specular = max0(getScreenSpaceReflections(fresnel, viewPos, material, mappedNormal, skylight));

    color += mix(diffuse, specular, clamp01(fresnel));

    color += getPointLight(playerPos, mat3(ap.camera.viewInv) * mappedNormal, mat3(ap.camera.viewInv) * faceNormal, material);

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
