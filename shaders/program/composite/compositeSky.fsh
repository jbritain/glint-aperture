#version 450 core

in vec2 uv;

uniform sampler2D sceneTex;
uniform sampler2D solidDepthTex;

#include "/lib/common.glsl"
#include "/lib/atmosphere/sky.glsl"

layout(location = 0) out vec4 color;

void main(){
    color = texture(sceneTex, uv);
    float depth = texture(solidDepthTex, uv).r;

    if(depth < 1.0){
        return;
    }

    vec3 viewPos = screenSpaceToViewSpace(vec3(uv, depth));
    vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
    vec3 worldDir = normalize(feetPlayerPos);

    color.rgb = getSky(color.rgb, worldDir, true);

}