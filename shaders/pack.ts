import type {} from "./iris";
import FlippableTexture from "./tslib/FlippableTexture";
import { setLightColors } from "./tslib/lightColors";

const maxPointLights = 64;
const lightRadius = 32;
const cascades = 4;
const shadowRes = 1592;

let cloudTexRead: ActiveTextureReference;
let cloudTexWrite: ActiveTextureReference;
let cloudTexA: BuiltTexture;
let cloudTexB: BuiltTexture;

let ssrTexRead: ActiveTextureReference;
let ssrTexWrite: ActiveTextureReference;
let ssrTexA: BuiltTexture;
let ssrTexB: BuiltTexture;

let cloudyFogTexRead: ActiveTextureReference;
let cloudyFogTexWrite: ActiveTextureReference;
let cloudyFogTexA: BuiltTexture;
let cloudyFogTexB: BuiltTexture;

export function configureRenderer(renderer: RendererConfig) {
  renderer.disableShade = true;
  renderer.sunPathRotation = 40.0;

  renderer.shadow.resolution = shadowRes;
  renderer.shadow.far = 512;
  renderer.shadow.distance = 512;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = cascades;

  renderer.shadow.entityCascadeCount = 1;
  renderer.render.clouds = false;

  renderer.pointLight.nearPlane = 0.1;
  renderer.pointLight.cacheRealTimeTerrain = true;
  renderer.pointLight.farPlane = lightRadius;

  renderer.pointLight.maxCount = maxPointLights;
  renderer.pointLight.realTimeCount = 4;
  renderer.pointLight.maxUpdates = 4;
  renderer.pointLight.updateThreshold = 0.08;

  renderer.mergedHandDepth = true;

  setLightColors();
}

export function beginFrame(state: WorldState) {
  cloudTexWrite.pointTo(state.currentFrame() % 2 == 0 ? cloudTexA : cloudTexB);
  cloudTexRead.pointTo(state.currentFrame() % 2 == 0 ? cloudTexB : cloudTexA);

  ssrTexWrite.pointTo(state.currentFrame() % 2 == 0 ? ssrTexA : ssrTexB);
  ssrTexRead.pointTo(state.currentFrame() % 2 == 0 ? ssrTexB : ssrTexA);

  cloudyFogTexWrite.pointTo(
    state.currentFrame() % 2 == 0 ? cloudyFogTexA : cloudyFogTexB,
  );
  cloudyFogTexRead.pointTo(
    state.currentFrame() % 2 == 0 ? cloudyFogTexB : cloudyFogTexA,
  );
}

export function configurePipeline(pipeline: PipelineConfig) {
  pipeline.addTag(0, new NamespacedId("minecraft", "leaves"));
  defineGlobally("TAG_LEAVES", "0");

  defineGlobally("LIGHT_RADIUS", lightRadius);
  defineGlobally("MAX_LIGHTS", maxPointLights);
  const lightListBinSize = 8;
  defineGlobally("LIGHT_LIST_BIN_SIZE", lightListBinSize);
  const lightListVolumeSize = 128;
  defineGlobally("LIGHT_LIST_VOLUME_SIZE", lightListVolumeSize);
  const lightListBinCount =
    Math.pow(lightListVolumeSize / lightListBinSize, 3) >> 0;
  const lightLightBinsPerAxis = lightListVolumeSize / lightListBinSize;
  defineGlobally("LIGHT_LIST_BIN_COUNT_AXIS", lightLightBinsPerAxis);
  defineGlobally("LIGHT_LIST_BIN_COUNT", lightListBinCount);
  const maxLightsPerBin = 64;
  defineGlobally("MAX_LIGHTS_PER_BIN", maxLightsPerBin);

  defineGlobally("CASCADES", cascades.toString());

  // we store maxLightsPerBin + 2 uints per bin, each representing an ID, plus the counters for how many lights occupy that bin
  const lightLists = pipeline.createBuffer(
    (maxLightsPerBin + 2) * lightListBinCount * 4,
    false,
  );

  // float for average luminance, float for centre depth
  const cameraData = pipeline.createBuffer(16, false);

  defineGlobally("EMISSION_STRENGTH", 10.0);

  const screenSetup = pipeline.forStage(Stage.SCREEN_SETUP);
  const preRender = pipeline.forStage(Stage.PRE_RENDER);
  const preTranslucent = pipeline.forStage(Stage.PRE_TRANSLUCENT);
  const postRender = pipeline.forStage(Stage.POST_RENDER);

  const sceneData = pipeline.createBuffer(32, false);

  const blueNoiseTex = pipeline.importPNGTexture(
    "blue_noise_tex",
    "textures/blue_noise.png",
    false,
    true,
  );

  const debugTex = pipeline
    .createImageTexture("debug_tex", "debug")
    .format(Format.RGBA8)
    .width(screenWidth)
    .height(screenHeight)
    .clear(true)
    .build();

  const previousSolidDepthTex = pipeline
    .createTexture("previousSolidDepthTex")
    .format(Format.R32F)
    .clear(false)
    .build();

  const previousMainDepthTex = pipeline
    .createTexture("previousMainDepthTex")
    .format(Format.R32F)
    .clear(false)
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
    .mipmap(false)
    .build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)"); // + multipleScatteringLUT.width.toString() + "," + multipleScatteringLUT.height.toString() + ")");

  const atmosphericFogLUT = pipeline
    .createImageTexture("atmospheric_fog_lut_tex", "atmospheric_fog_lut")
    .format(Format.RGBA16F)
    .width(32)
    .height(32)
    .depth(64)
    .clear(false)
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
    .createCompute("generate_atmospheric_fog_lut")
    .location("program/atmosphere/generate_atmospheric_fog_lut.csh")
    .workGroups(4, 4, 8)
    .compile();

  preRender.barrier(IMAGE_BIT);

  // CLOUDS
  // =======================================================================================
  const cloudShapeTex = pipeline
    .createImageTexture("cloud_shape_tex", "cloud_shape")
    .format(Format.RGBA16)
    .width(128)
    .height(128)
    .depth(128)
    .clear(false)
    .build();

  screenSetup
    .createCompute("generate_cloud_shape")
    .location("program/render_setup/generate_cloud_shape.csh")
    .workGroups(32, 32, 32)
    .compile();

  const cloudDetailTex = pipeline
    .createImageTexture("cloud_detail_tex", "cloud_detail")
    .format(Format.RGBA16)
    .width(32)
    .height(32)
    .depth(32)
    .clear(false)
    .build();

  screenSetup
    .createCompute("generate_cloud_detail")
    .location("program/render_setup/generate_cloud_detail.csh")
    .workGroups(8, 8, 8)
    .compile();

  const cloudWeatherTex = pipeline
    .createImageTexture("cloud_weather_tex", "cloud_weather")
    .format(Format.RGBA16)
    .width(512)
    .height(512)
    .clear(false)
    .build();

  preRender
    .createCompute("generate_cloud_weather")
    .location("program/render_setup/generate_cloud_weather.csh")
    .workGroups(64, 64, 1)
    .compile();

  preRender.barrier(IMAGE_BIT);

  const cloudSpheremapLUTTex = pipeline
    .createImageTexture("cloud_spheremap_tex", "cloud_spheremap")
    .format(Format.RGBA16F)
    .width(256)
    .height(256)
    .clear(false)
    .build();

  preRender
    .createCompute("generate_cloud_spheremap")
    .location("program/render_setup/generate_cloud_spheremap.csh")
    .workGroups(32, 32, 1)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preRender.barrier(IMAGE_BIT);

  const skyIrradianceLUT = pipeline
    .createImageTexture("sky_irradiance_lut_tex", "sky_irradiance_lut")
    .format(Format.RGBA16F)
    .width(32)
    .height(32)
    .clear(false)
    .build();

  preRender
    .createCompute("generate_sky_irradiance_lut")
    .location("program/render_setup/generate_sky_irradiance_lut.csh")
    .workGroups(4, 4, 1)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  // LIGHT LIST BINS
  // =======================================================================================
  preRender
    .createCompute("clearLightLists")
    .location("program/render_setup/clear_light_lists.csh")
    .workGroups(Math.ceil(lightListBinCount / 64), 1, 1)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  preRender.barrier(SSBO_BIT);

  preRender
    .createCompute("generateLightLists")
    .location("program/render_setup/generate_light_lists.csh")
    .workGroups(Math.ceil(maxPointLights / 64), 1, 1)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  preRender.barrier(SSBO_BIT);

  preRender
    .createCompute("propagateLightLists")
    .location("program/render_setup/propagate_light_lists.csh")
    .workGroups(
      Math.ceil(lightLightBinsPerAxis / 4),
      Math.ceil(lightLightBinsPerAxis / 4),
      Math.ceil(lightLightBinsPerAxis / 4),
    )
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

  pipeline
    .createObjectShader("clouds", Usage.CLOUDS)
    .vertex("program/geometry/discard.vsh")
    .fragment("program/geometry/discard.fsh")
    .compile();

  const translucentTex = pipeline
    .createTexture("translucent_tex")
    .format(Format.RGBA16F)
    .clear(true)
    .clearColor(0, 0, 0, 0)
    .build();

  const shadowTex = pipeline
    .createTexture("shadow_tex")
    .format(Format.RGBA8)
    .clear(true)
    .build();

  pipeline
    .createObjectShader("water", Usage.TERRAIN_TRANSLUCENT)
    .vertex("program/geometry/translucent.vsh")
    .fragment("program/geometry/translucent.fsh")
    .target(0, translucentTex)
    .target(1, gbufferTex1)
    .target(2, gbufferTex2)
    .target(3, shadowTex)
    .blendOff(1)
    .blendOff(2)
    .blendOff(3)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  // BEFORE TRANSLUCENTS
  // =======================================================================================

  const cloudShadowTex = pipeline
    .createArrayTexture("cloud_shadow_tex")
    .format(Format.R16F)
    .width(2048)
    .height(2048)
    .slices(cascades)
    .build();

  // preTranslucent
  //   .createArrayComposite("cloud_shadow_map")
  //   .vertex("program/fullscreen_pass.vsh")
  //   .fragment("program/before_translucents/generate_cloud_shadow_map.fsh")
  //   .target(0, cloudShadowTex)
  //   .build();

  preTranslucent
    .createComposite("opaque_shadowing")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_shadowing.fsh")
    .target(0, shadowTex)
    .compile();

  // const sceneTex = pipeline
  //   .createTexture("scene_tex")
  //   .format(Format.RGBA16F)
  //   .clear(true)
  //   .build();
  const sceneTex = new FlippableTexture("scene_tex")
    .format(Format.RGBA16F)
    .clear(false)
    .mipmap(true)
    .build(pipeline);

  preTranslucent
    .createComposite("sky")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/render_sky.fsh")
    .target(0, sceneTex.target)
    .compile();

  const diffuseTex = pipeline
    .createTexture("diffuse_tex")
    .format(Format.R11F_G11F_B10F)
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

  ssrTexA = pipeline
    .createTexture("ssr_tex_a")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  ssrTexB = pipeline
    .createTexture("ssr_tex_b")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  ssrTexWrite = pipeline.createTextureReference(
    "ssr_tex_w",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F,
  );

  ssrTexRead = pipeline.createTextureReference(
    "ssr_tex",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F,
  );

  preTranslucent
    .createComposite("opaque_ssr")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_ssr.fsh")
    .target(0, ssrTexWrite)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preTranslucent
    .createComposite("opaque_shading")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_shading.fsh")
    .target(0, sceneTex.target)
    .target(1, diffuseTex)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preTranslucent
    .createComposite("opaque_point_lights")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/opaque_point_lights.fsh")
    .target(0, sceneTex.target)
    .target(1, diffuseTex)
    .ssbo(0, lightLists)
    .define("LIGHT_LIST_BINDING", "0")
    .compile();

  cloudTexA = pipeline
    .createTexture("cloud_tex_a")
    .format(Format.RGBA16F)
    .width(Math.floor(screenWidth * 0.5))
    .height(Math.floor(screenHeight * 0.5))
    .clear(false)
    .build();

  cloudTexB = pipeline
    .createTexture("cloud_tex_b")
    .format(Format.RGBA16F)
    .width(Math.floor(screenWidth * 0.5))
    .height(Math.floor(screenHeight * 0.5))
    .clear(false)
    .build();

  cloudTexWrite = pipeline.createTextureReference(
    "cloud_tex_w",
    null,
    Math.floor(screenWidth * 0.5),
    Math.floor(screenHeight * 0.5),
    1,
    Format.RGBA16F,
  );

  cloudTexRead = pipeline.createTextureReference(
    "cloud_tex",
    null,
    Math.floor(screenWidth * 0.5),
    Math.floor(screenHeight * 0.5),
    1,
    Format.RGBA16F,
  );

  preTranslucent
    .createComposite("render_clouds")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/render_clouds.fsh")
    .target(0, cloudTexWrite)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  preTranslucent
    .createComposite("blend_clouds")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/before_translucents/blend_clouds.fsh")
    .target(0, sceneTex.target)
    .compile();

  // POST RENDER
  // =======================================================================================

  postRender
    .createComposite("water_fog_outside_water")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/water_fog.fsh")
    .target(0, sceneTex.target)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .define("CONDITION", "is_water && !in_water")
    .define("START_POS", "translucent_player_pos")
    .define("END_POS", "opaque_player_pos")
    .compile();

  sceneTex.flip();

  postRender
    .createComposite("blend_translucents")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/translucent_shading.fsh")
    .target(0, sceneTex.target)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  sceneTex.unflip();

  cloudyFogTexA = pipeline
    .createTexture("cloudy_fog_tex_a")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  cloudyFogTexB = pipeline
    .createTexture("cloudy_fog_tex_b")
    .format(Format.RGBA16F)
    .clear(false)
    .build();

  cloudyFogTexWrite = pipeline.createTextureReference(
    "cloudy_fog_tex_w",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F,
  );

  cloudyFogTexRead = pipeline.createTextureReference(
    "cloudy_fog_tex",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F,
  );

  postRender
    .createComposite("render_cloudy_fog")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/render_cloudy_fog.fsh")
    .target(0, cloudyFogTexWrite)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .compile();

  postRender
    .createComposite("blend_cloudy_fog")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/blend_cloudy_fog.fsh")
    .target(0, sceneTex.target)
    .compile();

  postRender
    .createComposite("water_fog_inside_water")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/water_fog.fsh")
    .target(0, sceneTex.target)
    .ssbo(0, sceneData)
    .define("SCENE_DATA_BINDING", "0")
    .define("CONDITION", "in_water")
    .define("START_POS", "vec3(0.0)")
    .define("END_POS", "translucent_player_pos")
    .compile();

  postRender
    .createComposite("luminance_alpha")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/write_luminance_to_alpha.fsh")
    .target(0, sceneTex.target)
    .compile();

  postRender.generateMips(sceneTex.target);

  postRender
    .createCompute("fetch_camera_data")
    .workGroups(1, 1, 1)
    .location("program/post/fetch_camera_data.csh")
    .ssbo(0, cameraData)
    .define("CAMERA_DATA_BINDING", "0")
    .compile();

  postRender
    .createComposite("exposure")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/post/exposure.fsh")
    .target(0, sceneTex.target)
    .ssbo(0, cameraData)
    .define("CAMERA_DATA_BINDING", "0")
    .compile();

  const bloomTex = pipeline
    .createTexture("bloom_tex")
    .format(Format.RGBA16F)
    .clear(true)
    .mipmap(true)
    .build();

  for (let i = 0; i < 5; i++) {
    postRender
      .createComposite(`bloom_downsample${i}-${i + 1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_downsample.fsh")
      .target(0, bloomTex, i + 1)
      .define("BLOOM_INDEX", i.toString())
      .compile();
  }

  for (let i = 5; i > 0; i -= 1) {
    postRender
      .createComposite(`bloom_upsample${i}-${i - 1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_upsample.fsh")
      .target(0, bloomTex, i - 1)
      .define("BLOOM_INDEX", i.toString())
      .compile();
  }

  postRender
    .createComposite("copy_previous_main_depth")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/buffer_copy.fsh")
    .target(0, previousMainDepthTex)
    .define("SAMPLE_BUFFER", "mainDepthTex")
    .compile();

  postRender
    .createComposite("copy_previous_solid_depth")
    .vertex("program/fullscreen_pass.vsh")
    .fragment("program/buffer_copy.fsh")
    .target(0, previousSolidDepthTex)
    .define("SAMPLE_BUFFER", "solidDepthTex")
    .compile();

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
