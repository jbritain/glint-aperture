#version 450 core

layout(location = 0) out vec4 color;

uniform sampler2DArrayShadow shadowMap;

in vec2 uv;
in vec2 light;
in vec4 vertColor;
in vec3 viewPos;
in vec3 normal;

#include "/lib/common.glsl"
#include "/lib/shadowSpace.glsl"

void iris_emitFragment() {
	vec2 mUV = uv, mLight = light;
	vec4 mColor = vertColor;

	iris_modifyBase(mUV, mColor, mLight);

	color = iris_sampleBaseTex(mUV) * mColor * iris_sampleLightmap(mLight);

	if (iris_discardFragment(color)) discard;

	vec3 feetPlayerPos = (playerModelViewInverse * vec4(viewPos, 1.0)).xyz;
	int cascade;
	vec3 shadowScreenPos = getShadowScreenPos(feetPlayerPos, normal, cascade);

	if(clamp01(shadowScreenPos.xy) == shadowScreenPos.xy){
		color.rgb *= (texture(shadowMap, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r * clamp01(dot(normal, lightDir))) * 0.5 + 0.5;
	}
	

	color.rgb = pow(color.rgb, vec3(2.2));
}