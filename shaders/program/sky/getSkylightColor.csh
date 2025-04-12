#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;



#include "/lib/common.glsl"


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

            radiance += getValFromSkyLUT(tbn * dir, 4) / (cosTheta / PI);
        }
    }

    radiance /= pow2(samples);
    radiance = max0(radiance);
    skylightColor = radiance;

}