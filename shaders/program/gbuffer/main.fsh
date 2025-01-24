#version 450 core

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 gbufferData1;
layout(location = 2) out vec4 gbufferData2;

uniform sampler2DArray shadowMap;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArray shadowColorTex;

in vec2 uv;
in vec2 light;
in vec4 vertColor;
in vec3 viewPos;
in mat3 tbnMatrix;
flat in uint blockID;

#include "/lib/common.glsl"
#include "/lib/lighting/shading.glsl"

void iris_emitFragment() {
	vec2 mUV = uv, mLight = light;
	vec4 mColor = vertColor;

	iris_modifyBase(mUV, mColor, mLight);

	color = iris_sampleBaseTex(mUV) * mColor * iris_sampleLightmap(mLight);
	color.rgb = pow(color.rgb, vec3(2.2));
	vec3 albedo = color.rgb;

	if (iris_discardFragment(color)) discard;

	vec4 normalData = iris_sampleNormalMap(mUV);
  vec4 specularData = iris_sampleSpecularMap(mUV);

	GbufferData gbufferData;
	gbufferData.lightmap = light;
	gbufferData.faceNormal = tbnMatrix[2];

	gbufferData.mappedNormal = normalData.xyz * 2.0 - 1.0;
	gbufferData.mappedNormal.z = sqrt(1.0 - dot(gbufferData.mappedNormal.xy, gbufferData.mappedNormal.xy)); // reconstruct z due to labPBR encoding
	gbufferData.mappedNormal = tbnMatrix * gbufferData.mappedNormal;

	gbufferData.material = materialFromSpecularMap(albedo.rgb, specularData);
	gbufferData.materialMask = buildMaterialMask(blockID);
	overrideMaterials(gbufferData.material, gbufferData.materialMask);

	#ifdef FORWARD_LIGHTING
	color.rgb = getShadedColor(gbufferData.material, gbufferData.mappedNormal, tbnMatrix[2], light, viewPos);
	#endif

	encodeGbufferData(gbufferData1, gbufferData2, gbufferData, specularData);
}