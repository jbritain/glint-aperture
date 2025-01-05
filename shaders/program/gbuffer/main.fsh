#version 450 core

layout(location = 0) out vec4 color;

uniform sampler2DArrayShadow shadowMap;

in vec2 uv;
in vec2 light;
in vec4 vertColor;
in vec3 viewPos;
in mat3 tbnMatrix;

#include "/lib/common.glsl"
#include "/lib/lighting/shading.glsl"

void iris_emitFragment() {
	vec2 mUV = uv, mLight = light;
	vec4 mColor = vertColor;

	iris_modifyBase(mUV, mColor, mLight);

	color = iris_sampleBaseTex(mUV) * mColor * iris_sampleLightmap(mLight);
	vec3 albedo = color.rgb;

	if (iris_discardFragment(color)) discard;

	vec4 normalData = iris_sampleNormalMap(mUV);
    vec4 specularData = iris_sampleSpecularMap(mUV);

	vec3 mappedNormal = normalData.xyz * 2.0 - 1.0;
	mappedNormal.z = sqrt(1.0 - dot(mappedNormal.xy, mappedNormal.xy)); // reconstruct z due to labPBR encoding
	mappedNormal = tbnMatrix * mappedNormal;

	Material material = materialFromSpecularMap(albedo.rgb, specularData);

	color.rgb = getShadedColor(material, mappedNormal, tbnMatrix[2], light, viewPos);


	color.rgb = pow(color.rgb, vec3(2.2));
}