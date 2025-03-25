#ifndef SAMPLERS_GLSL
#define SAMPLERS_GLSL

#ifdef SKY_SAMPLERS
uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;
uniform sampler2D skyViewLUTTex;
uniform sampler2D cloudSkyLUTTex;
#endif

uniform sampler2D sceneTex;

#ifdef GBUFFER_SAMPLERS
uniform sampler2D translucentsTex;
uniform sampler2D gbufferDataTex1;
uniform sampler2D gbufferDataTex2;
uniform sampler2D previousSceneTex;
uniform sampler2D previousDepthTex;
uniform sampler2D globalIlluminationTex;
#endif

#ifdef BLOOM_ENABLE
uniform sampler2D bloomTex;
#endif

#ifdef DOF_SAMPLERS
uniform sampler2D DoFCoCTex;
uniform sampler2D DoFTex;
#endif

uniform sampler2D blueNoiseTex;

#ifdef CLOUD_NOISE_SAMPLERS
uniform sampler2D worleyNoiseTex;
uniform sampler2D perlinNoiseTex;
uniform sampler3D cloudShapeNoiseTex;
uniform sampler3D cloudErosionNoiseTex;
uniform sampler2D cloudHeightGradientTex;
#endif

uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

#ifdef SHADOW_SAMPLERS
uniform sampler2DArray shadowMap;
uniform sampler2DArray solidShadowMap;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;

uniform sampler2DArray shadowColorTex;
uniform sampler2DArray shadowNormalTex;
uniform sampler2DArray shadowPositionTex;
uniform usampler2DArray shadowMaskTex;

uniform sampler2D
#endif

#ifdef VOXEL_SAMPLERS
uniform sampler3D floodFillVoxelMapTex1;
uniform sampler3D floodFillVoxelMapTex2;
uniform usampler3D voxelMapTex;
#endif


#endif // SAMPLERS_GLSL
