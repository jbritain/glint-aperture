#version 450 core

layout(location = 0) out vec4 color;

uniform sampler2DArrayShadow shadowMap;

in vec2 uv;
in vec2 light;
in vec4 vertColor;
in vec3 viewPos;
in vec3 normal;

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

	if(clamp(shadowScreenPos.xy, vec2(0.0), vec2(1.0)) == shadowScreenPos.xy){
		color.rgb *= (texture(shadowMap, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z)).r * clamp(dot(normal, normalize(shadowLightPosition)), 0.0, 1.0)) * 0.5 + 0.5;
	}
	

	color.rgb = pow(color.rgb, vec3(2.2));

	// color.rgb = viewPos;
}