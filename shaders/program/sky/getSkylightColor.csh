#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;

#include "/lib/common.glsl"

uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;
uniform sampler2D skyViewLUTTex;

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/sky.glsl"

void main(){
    int samples = 16;
    
    vec3 radiance = vec3(0.0);

    mat3 tbn = mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0),
        vec3(0.0, 1.0, 0.0)
    );

    for(int i = 0; i < samples; i++){
        float cosTheta = sqrt(float(i)/samples);

        if(cosTheta < 1e-9){
            continue;
        }

        float sinTheta = sqrt(1.0 - pow2(cosTheta));

        for(int j = 0; j < samples;  j++){
            float phi = 2 * PI * (float(j)/samples);

            vec3 dir = vec3(
                cos(phi) * sinTheta,
                sin(phi) * sinTheta,
                cosTheta
            );

            radiance += getSky(tbn * dir, false) / (cosTheta / PI);
        }
    }

    radiance /= pow2(samples);
    radiance = max0(radiance);
    skylightColor = radiance;

}