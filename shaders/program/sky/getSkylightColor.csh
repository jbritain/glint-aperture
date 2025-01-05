#version 450 core

layout (local_size_x = 1, local_size_y = 1) in;

#include "/lib/common.glsl"

uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;
uniform sampler2D skyViewLUTTex;

#include "/lib/buffers/sceneData.glsl"
#include "/lib/atmosphere/sky.glsl"

void main(){
    int samples = 0;
    float sampleDelta = 0.4;

    for(float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta){
        float cosPhi = cos(phi);
        float sinPhi = sin(phi);

        for(float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta){
            float cosTheta = cos(theta);
            float sinTheta = sin(theta);

            vec3 dir = vec3(
                sinTheta * cosPhi,
                cosTheta,
                sinTheta * sinPhi
            );

            skylightColor += getSky(dir, false);
            samples++;
        }
    }

    skylightColor /= float(samples);
    skylightColor *= 2.0;

}