#ifndef SAMPLERS_GLSL
#define SAMPLERS_GLSL

uniform sampler2D sunTransmittanceLUTTex;
uniform sampler2D multipleScatteringLUTTex;
uniform sampler2D skyViewLUTTex;
uniform sampler2D sceneTex;
uniform sampler2D translucentsTex;
uniform sampler2D gbufferDataTex1;
uniform sampler2D gbufferDataTex2;
uniform sampler2D previousSceneTex;
uniform sampler2D previousDepthTex;
uniform sampler2D globalIlluminationTex;

#ifdef BLOOM_ENABLE
uniform sampler2D bloomTex;
#endif

uniform sampler2D blueNoiseTex;

uniform sampler2D mainDepthTex;
uniform sampler2D solidDepthTex;

uniform sampler2DArray shadowMap;
uniform sampler2DArray solidShadowMap;
uniform sampler2DArrayShadow shadowMapFiltered;
uniform sampler2DArrayShadow solidShadowMapFiltered;

uniform sampler2DArray shadowColorTex;
uniform sampler2DArray shadowNormalTex;
uniform sampler2DArray shadowPositionTex;
uniform usampler2DArray shadowMaskTex;

uniform sampler3D floodFillVoxelMapTex1;
uniform sampler3D floodFillVoxelMapTex2;
uniform usampler3D voxelMapTex;

#endif // SAMPLERS_GLSL
