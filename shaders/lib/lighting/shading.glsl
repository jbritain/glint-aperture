#ifndef SHADING_GLSL
#define SHADING_GLSL

#include "/lib/lighting/brdf.glsl"
#include "/lib/lighting/shadows.glsl"
#include "/lib/buffers/sceneData.glsl"

vec3 getShadedColor(Material material, vec3 mappedNormal, vec3 faceNormal, vec2 lightmap, vec3 viewPos){
    vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

    float scatter;
    vec3 shadow = getShadowing(playerPos, faceNormal, lightmap, material, scatter);

    vec3 color = brdf(material, mappedNormal, faceNormal, viewPos, shadow, scatter) * sunlightColor;

    vec3 diffuse = 
        skylightColor * pow2(lightmap.y) * (material.ao * 0.5 + 0.5) +
        pow(vec3(255, 152, 54), vec3(2.2)) * 1e-8 * max0(exp(-(1.0 - lightmap.x * 10.0))) +
        vec3(0.05) * material.ao

        
    ;

    color += diffuse * material.albedo;

    color += material.emission * material.albedo * 16.0;

    return color;
}
