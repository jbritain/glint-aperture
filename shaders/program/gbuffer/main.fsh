#version 450 core

uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

uniform sampler3D floodFillVoxelMapTex1;
uniform sampler3D floodFillVoxelMapTex2;

uniform sampler2D globalIlluminationTex;

uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;
uniform sampler2DArray shadowMap;
uniform sampler2DArray solidShadowMap;
uniform sampler2DArray shadowColorTex;
uniform usampler2DArray shadowMaskTex;
uniform samplerCubeArray pointLight;
uniform samplerCubeArrayShadow pointLightFiltered;

uniform sampler2D previousDepthTex;
uniform sampler2D previousSceneTex;

uniform sampler2D cloudSkyLUTTex;

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 gbufferData1;
layout(location = 2) out vec4 gbufferData2;



in vec2 uv;
in vec2 light;
in vec4 vertColor;
in vec3 viewPos;
in mat3 tbnMatrix;
flat in uint blockID;

in vec3 midBlock;

in vec4 textureBounds;
in vec2 singleTexSize;






#include "/lib/common.glsl"
#include "/lib/lighting/shading.glsl"
#include "/lib/water/waveNormals.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/lighting/directionalLightmaps.glsl"
#include "/lib/misc/parallax.glsl"
#include "/lib/voxel/voxelMap.glsl"

void iris_emitFragment() {
	vec2 mUV = uv, mLight = light;
	vec4 mColor = vertColor;

	iris_modifyBase(mUV, mColor, mLight);

	vec3 parallaxPos;
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	mUV = getParallaxTexcoord(mUV, viewPos, tbnMatrix, parallaxPos, dx, dy, 0.0, textureBounds, singleTexSize, midBlock);

	color = iris_sampleBaseTex(mUV) * mColor;
	color.rgb = pow(color.rgb, vec3(2.2));
	vec3 albedo = color.rgb;

	if (iris_discardFragment(color)) discard;

	vec3 playerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

	vec4 normalData = iris_sampleNormalMap(mUV);
  vec4 specularData = iris_sampleSpecularMap(mUV);

	GbufferData gbufferData;
	gbufferData.lightmap = light;
	gbufferData.faceNormal = tbnMatrix[2];

	gbufferData.mappedNormal = normalData.xyz * 2.0 - 1.0;
	gbufferData.mappedNormal.z = sqrt(1.0 - dot(gbufferData.mappedNormal.xy, gbufferData.mappedNormal.xy)); // reconstruct z due to labPBR encoding
	gbufferData.mappedNormal = tbnMatrix * gbufferData.mappedNormal;

	vec3 worldFaceNormal = mat3(ap.camera.viewInv) * gbufferData.faceNormal;
	vec3 worldMappedNormal = mat3(ap.camera.viewInv) * gbufferData.mappedNormal;

	gbufferData.material = materialFromSpecularMap(albedo.rgb, specularData, normalData.b);
	gbufferData.materialMask = buildMaterialMask(blockID);

	if(color.a >= 0.99){
		gbufferData.materialMask.isFluid = false;
	}

	overrideMaterials(gbufferData.material, gbufferData.materialMask);

	if(gbufferData.materialMask.isFluid){
		gbufferData.mappedNormal = normalize(mat3(ap.camera.view) * waveNormal((ap.camera.viewInv * vec4(viewPos, 1.0)).xz + ap.camera.pos.xz, worldFaceNormal, sin(PI * 0.5 * clamp01(abs(dot(gbufferData.faceNormal, normalize(viewPos)))))));
		gbufferData.material.albedo = vec3(0.0);
	}



	applyDirectionalLightmap(gbufferData.lightmap, viewPos, gbufferData.mappedNormal, tbnMatrix, gbufferData.material.sss);

	#ifdef FORWARD_LIGHTING
	vec3 fresnel;
	if(!gbufferData.materialMask.isFluid){
		vec3 blocklightColor;
		vec3 voxelPos = mapVoxelPosInterp(playerPos - worldFaceNormal * 0.5 + mat3(ap.camera.viewInv) * worldMappedNormal);
		if(EVEN_FRAME){
			blocklightColor = textureLod(floodFillVoxelMapTex2, voxelPos, 0).rgb / FLOODFILL_SCALING;
		} else {
			blocklightColor = textureLod(floodFillVoxelMapTex1, voxelPos, 0).rgb / FLOODFILL_SCALING;
		}
		color.rgb = getShadedColor(gbufferData.material, gbufferData.mappedNormal, tbnMatrix[2], light.y, blocklightColor, viewPos, fresnel);
	} else {
		color.a = 0.0;
	}

	
	#endif



	float encodedMaterialMask = encodeMaterialMask(gbufferData.materialMask);
	MaterialMask decodedMaterialMask = decodeMaterialMask(encodedMaterialMask);

	encodeGbufferData(gbufferData1, gbufferData2, gbufferData, specularData);
}