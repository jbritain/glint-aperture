#version 460 core

#define CLOUD_NOISE_SAMPLERS

#include "/lib/common.glsl"

in vec2 uv;
out vec4 fragColor;

vec3 uncharted2TonemapPartial(vec3 x)
{
    float A = 0.15f;
    float B = 0.50f;
    float C = 0.10f;
    float D = 0.20f;
    float E = 0.02f;
    float F = 0.30f;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 uncharted2FilmicTonemap(vec3 v)
{
    float exposure_bias = 2.0f;
    vec3 curr = uncharted2TonemapPartial(v * exposure_bias);

    vec3 W = vec3(11.2f);
    vec3 white_scale = vec3(1.0f) / uncharted2TonemapPartial(W);
    return pow(curr * white_scale, vec3(rcp(2.2)));
}

vec3 ACESFilm(vec3 x){
    x *= 0.5;
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return pow(clamp01((x*(a*x+b))/(x*(c*x+d)+e)), vec3(rcp(2.2)));
}

uniform sampler2D debugTex;

void main() {
	fragColor = texture(sceneTex, uv);

    #ifdef BLOOM_ENABLE
    fragColor.rgb = mix(fragColor.rgb, texture(bloomTex, uv).rgb, 0.01);
    #endif

    fragColor.rgb *= 0.5;

	fragColor.rgb = ACESFilm(fragColor.rgb);

    #ifdef DEBUG_ENABLE
    fragColor.rgb = texture(debugTex, uv).rgb;
    #endif

    // fragColor.rgb = vec3(texture(cloudShapeNoiseTex, vec3(0.0, uv)).r);
}
