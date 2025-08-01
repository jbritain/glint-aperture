import type {} from "./iris";
import { setLightColors } from "./tslib/lightColors";

const maxPointLights = 128;
const cascades = 4;

export function configureRenderer(renderer: RendererConfig) {
  renderer.disableShade = true;
  renderer.sunPathRotation = 40.0;

  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = cascades;

  renderer.shadow.entityCascadeCount = 1;

  renderer.pointLight.nearPlane = 0.1;
  renderer.pointLight.cacheRealTimeTerrain = true;
  renderer.pointLight.farPlane = 16.0;

  renderer.pointLight.maxCount = maxPointLights;
  renderer.pointLight.realTimeCount = 4;
  renderer.pointLight.maxUpdates = 4;
  renderer.pointLight.updateThreshold = 0.1;

  renderer.mergedHandDepth = true;

  setLightColors();
}

export function configurePipeline(pipeline: PipelineConfig) {
  pipeline.addTag(0, new NamespacedId("minecraft", "leaves"));
  defineGlobally("TAG_LEAVES", "0");

  const lightListBinSize = 16;
  defineGlobally("LIGHT_LIST_BIN_SIZE", lightListBinSize);
  const lightListVolumeSize = 256;
  defineGlobally("LIGHT_LIST_VOLUME_SIZE", lightListVolumeSize);
  const lightListBinCount =
    Math.pow(lightListVolumeSize / lightListBinSize, 3) >> 0;
  defineGlobally(
    "LIGHT_LIST_BIN_COUNT_AXIS",
    lightListVolumeSize / lightListBinSize,
  );
  defineGlobally("LIGHT_LIST_BIN_COUNT", lightListBinCount);
  const maxLightsPerBin = 128;
  defineGlobally("MAX_LIGHTS_PER_BIN", maxLightsPerBin);

  defineGlobally("CASCADES", cascades.toString());

  // we store maxLightsPerBin + 1 uints per bin, each representing an ID, plus the counter for how many lights occupy that bin
  const lightLists = pipeline.createBuffer(
    (maxLightsPerBin + 1) * lightListBinCount * 4,
    false,
  );

  defineGlobally("EMISSION_STRENGTH", 100.0);

  const screenSetup = pipeline.forStage(Stage.SCREEN_SETUP);
  const preRender = pipeline.forStage(Stage.PRE_RENDER);
  const preTranslucent = pipeline.forStage(Stage.PRE_TRANSLUCENT);
  const postRender = pipeline.forStage(Stage.POST_RENDER);

  const sceneData = pipeline.createBuffer(16, true);

  const blueNoiseTex = pipeline.importPNGTexture(
    "blue_noise_tex",
    "textures/blue_noise.png",
    false,
    true,
  );

  const debugTex = pipeline
    .createImageTexture("debug_tex", "debug")
    .format(Format.RGBA8)
    .clear(true)
    .build();

  // SKY
  // =======================================================================================

  const sunTransmittanceLUT = pipeline
    .createImageTexture("sun_transmittance_lut_tex", "sun_transmittance_lut")
    .format(Format.RGBA16F)
    .width(256)
    .height(64)
    .clear(false)
    .build();
  // defineGlobally("SUN_TRANSMITTANCE_RES", `ivec2(${sunTransmittanceLUT.width}, ${sunTransmittanceLUT.height})`);

  const multipleScatteringLUT = pipeline
    .createImageTexture(
      "multiple_scattering_lut_tex",
      "multiple_scattering_lut",
    )
    .format(Format.RGBA16F)
    .width(32)
    .height(32)
    .clear(false)
    .build();
  // defineGlobally("MULTIPLE_SCATTERING_RES", `ivec2(${multipleScatteringLUT.width}, ${multipleScatteringLUT.height})`);

  const skyViewLUT = pipeline
    .createImageTexture("sky_view_lut_tex", "sky_view_lut")
    .format(Format.RGBA16F)
    .width(200)
    .height(200)
    .clear(true)
    .mipmap(true)
    .build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)"); // + multipleScatteringLUT.width.toString() + "," + multipleScatteringLUT.height.toString() + ")");

  const skyIrradianceLUT = pipeline
    .createImageTexture("sky_irradiance_lut_tex", "sky_irradiance_lut")
    .format(Format.RGBA16F)
    .width(32)
    .height(32)
    .clear(true)
    .build();

  screenSetup
    .createCompute("generate_sun_transmittance_lut")
    .location("program/atmosphere/generate_sun_transmittance_lut.csh")
    .workGroups(32, 8, 1)
    .compile();

  screenSetup.barrier(IMAGE_BIT);
  screenSetup
    .createCompute("generate_multiple_scattering_lut")
    .location("program/atmosphere/generate_multiple_scattering_lut.csh")
    .workGroups(4, 4, 1)
    .compile();

  preRender.barrier(IMAGE_BIT);
  preRender
    .createCompute("generate_sky_view_lut")
    .location("program/atmosphere/generate_sky_view_lut.csh")
    .workGroups(25, 25, 1)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preRender.barrier(IMAGE_BIT);
  preRender
    .createCompute("generateSkyIrradianceLUT")
    .location("program/render_setup/generate_sky_irradiance_lut.csh")
    .workGroups(4, 4, 1)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preRender.barrier(IMAGE_BIT);

  // LIGHT LIST BINS
  // =======================================================================================
  preRender
    .createCompute("clearLightList")
    .location("program/render_setup/clear_light_lists.csh")
    .workGroups(Math.ceil(lightListBinCount / 64), 1, 1)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  preRender.barrier(SSBO_BIT);

  preRender
    .createCompute("generateLightList")
    .location("program/render_setup/generate_light_lists.csh")
    .workGroups(Math.ceil(maxPointLights / 64), 1, 1)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  // GEOMETRY
  // =======================================================================================
  pipeline
    .createObjectShader("shadow", Usage.SHADOW)
    .vertex("program/geometry/shadow.vsh")
    .fragment("program/geometry/shadow.fsh")
    .compile();

  pipeline
    .createObjectShader("point_shadow", Usage.POINT)
    .vertex("program/geometry/point_shadow.vsh")
    .fragment("program/geometry/point_shadow.fsh")
    .compile();

  const gbufferTex1 = pipeline
    .createTexture("gbuffer_tex_1")
    .format(Format.RGBA16)
    .clear(true)
    .build();

  const gbufferTex2 = pipeline
    .createTexture("gbuffer_tex_2")
    .format(Format.RGBA16)
    .clear(true)
    .build();

  pipeline
    .createObjectShader("terrain", Usage.TEXTURED)
    .vertex("program/geometry/opaque.vsh")
    .fragment("program/geometry/opaque.fsh")
    .target(0, gbufferTex1)
    .target(1, gbufferTex2)
    .compile();

  // BEFORE TRANSLUCENTS
  // =======================================================================================
  const shadowTex = pipeline
    .createTexture("shadow_tex")
    .format(Format.RGBA8)
    .clear(true)
    .build();

  preTranslucent
    .createComposite("opaque_shadowing")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_shadowing.fsh")
    .target(0, shadowTex)
    .compile();

  const sceneTex = pipeline
    .createTexture("scene_tex")
    .format(Format.RGBA16F)
    .clear(true)
    .build();

  preTranslucent
    .createComposite("sky")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/render_sky.fsh")
    .target(0, sceneTex)
    .compile();

  const diffuseTex = pipeline
    .createTexture("diffuse_tex")
    .format(Format.R11F_G11F_B10F)
    .clear(false)
    .build();

  const specularTex = pipeline
    .createTexture("specular_tex")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  // const globalIlluminationTex = pipeline
  //   .createTexture("global_illumination_tex")
  //   .format(Format.RGBA16F)
  //   .clear(false)
  //   .build();

  // preTranslucent
  //   .createComposite("global_illumination")
  //   .vertex("program/fullscreen_pass.vsh")
  //   .fragment("program/before_translucents/gtao.fsh")
  //   .target(0, globalIlluminationTex)
  //   .ssbo(0, sceneData)
  //   .compile();

  const ssrTex = pipeline
    .createTexture("ssr_tex")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  preTranslucent
    .createComposite("opaque_ssr")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_ssr.fsh")
    .target(0, ssrTex)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preTranslucent
    .createComposite("opaque_shading")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_shading.fsh")
    .target(0, sceneTex)
    .target(1, diffuseTex)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preTranslucent
    .createComposite("opaque_point_lights")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_point_lights.fsh")
    .target(0, sceneTex)
    .target(1, diffuseTex)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  // POST RENDER
  // =======================================================================================

  postRender
    .createComposite("exposure")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/exposure.fsh")
    .target(0, sceneTex)
    .compile();

  const bloomTex = pipeline
    .createTexture("bloom_tex")
    .format(Format.RGBA16F)
    .clear(true)
    .mipmap(true)
    .build();

  for (let i = 0; i < 5; i++) {
    postRender
      .createComposite(`bloom_ownsample${i}-${i + 1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_downsample.fsh")
      .target(0, bloomTex, i + 1)
      .define("BLOOM_INDEX", i.toString())
      .compile();
  }

  for (let i = 5; i > 0; i -= 1) {
    postRender
      .createComposite(`bloomUpsample${i}-${i - 1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_upsample.fsh")
      .target(0, bloomTex, i - 1)
      .define("BLOOM_INDEX", i.toString())
      .compile();
  }

  screenSetup.end();
  preRender.end();
  preTranslucent.end();
  postRender.end();

  pipeline
    .createCombinationPass("program/combination.fsh")
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();
}
