#version 460 core

uniform sampler2D sceneTex;
uniform sampler2DArray shadowColorTex;

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

void main() {
	fragColor = texture(sceneTex, uv);

	fragColor.rgb = uncharted2FilmicTonemap(fragColor.rgb);

    // fragColor = texture(shadowColorTex, vec3(uv, 3));
}
