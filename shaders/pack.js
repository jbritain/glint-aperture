var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);

// tslib/FlippableTexture.ts
var FlippableTexture = class {
  constructor(name) {
    __publicField(this, "name");
    __publicField(this, "_imageName");
    __publicField(this, "_format");
    __publicField(this, "_width");
    __publicField(this, "_height");
    __publicField(this, "_depth");
    __publicField(this, "clearColorR");
    __publicField(this, "clearColorG");
    __publicField(this, "clearColorB");
    __publicField(this, "clearColorA");
    __publicField(this, "_clear");
    __publicField(this, "_mipmap");
    __publicField(this, "flipped", false);
    __publicField(this, "unflipped", true);
    __publicField(this, "textureA");
    __publicField(this, "textureB");
    this.name = name;
  }
  format(internalFormat) {
    this._format = internalFormat;
    return this;
  }
  width(width) {
    this._width = width;
    return this;
  }
  height(height) {
    this._height = height;
    return this;
  }
  depth(depth) {
    this._depth = depth;
    return this;
  }
  clearColor(r, g, b, a) {
    this.clearColorR = r;
    this.clearColorG = g;
    this.clearColorB = b;
    this.clearColorA = a;
    return this;
  }
  clear(clear) {
    this._clear = clear;
    return this;
  }
  mipmap(mipmap) {
    this._mipmap = mipmap;
    return this;
  }
  imageName(imageName) {
    this._imageName = imageName;
    return this;
  }
  build(pipeline) {
    if (this._imageName) {
      this.textureA = pipeline.createImageTexture(
        this.name + "_a",
        this._imageName + "_a"
      );
      this.textureB = pipeline.createImageTexture(
        this.name + "_b",
        this._imageName + "_b"
      );
    } else {
      this.textureA = pipeline.createTexture(this.name + "_a");
      this.textureB = pipeline.createTexture(this.name + "_b");
    }
    if (this._format) {
      this.textureA.format(this._format);
      this.textureB.format(this._format);
    }
    if (this._width) {
      this.textureA.width(this._width);
      this.textureB.width(this._width);
    }
    if (this._height) {
      this.textureA.height(this._height);
      this.textureB.height(this._height);
    }
    if (this._depth) {
      this.textureA.depth(this._depth);
      this.textureB.depth(this._depth);
    }
    if (this.clearColorR) {
      this.textureA.clearColor(
        this.clearColorR,
        this.clearColorG,
        this.clearColorB,
        this.clearColorA
      );
      this.textureB.clearColor(
        this.clearColorR,
        this.clearColorG,
        this.clearColorB,
        this.clearColorA
      );
    }
    if (this._clear) {
      this.textureA.clear(this._clear);
      this.textureB.clear(this._clear);
    }
    if (this._mipmap) {
      this.textureA.mipmap(this._mipmap);
      this.textureB.mipmap(this._mipmap);
    }
    this.textureA = this.textureA.build();
    this.textureB = this.textureB.build();
    defineGlobally(this.name, this.sampler);
    return this;
  }
  get sampler() {
    return this.name + (this.flipped ? "_a" : "_b");
  }
  get target() {
    return this.flipped != this.unflipped ? this.textureB : this.textureA;
  }
  // Swaps the sampler and rendertarget buffers. If the texture is currently "unflipped", this will cause the rendertarget to move, but the sampler to remain the same, meaning whatever was last written is still accessable in the sampler.
  flip() {
    if (this.unflipped) print("unflipped, disabling");
    if (!this.unflipped) this.flipped = !this.flipped;
    print("flipped: " + this.flipped);
    this.unflipped = false;
    defineGlobally(this.name, this.sampler);
  }
  // Causes the rendertarget to point to the same buffer as the sampler until the next flip operation. This is the default state.
  unflip() {
    if (this.unflipped) return;
    this.flipped = !this.flipped;
    this.unflipped = true;
    defineGlobally(this.name, this.sampler);
  }
};

// tslib/lightColors.ts
function setLightColors() {
  setLightColor(new NamespacedId("campfire"), 255, 102, 0, 255);
  setLightColor(new NamespacedId("candle"), 245, 127, 68, 255);
  setLightColor(new NamespacedId("cave_vines"), 243, 133, 59, 255);
  setLightColor(new NamespacedId("cave_vines_plant"), 243, 133, 59, 255);
  setLightColor(new NamespacedId("glow_lichen"), 107, 238, 172, 255);
  setLightColor(new NamespacedId("lantern"), 243, 158, 73, 255);
  setLightColor(new NamespacedId("jack_o_lantern"), 193, 100, 38, 255);
  setLightColor(new NamespacedId("magma_block"), 193, 100, 38, 255);
  setLightColor(new NamespacedId("ochre_froglight"), 223, 172, 71, 255);
  setLightColor(new NamespacedId("pearlescent_froglight"), 224, 117, 232, 255);
  setLightColor(new NamespacedId("redstone_torch"), 249, 50, 28, 255);
  setLightColor(new NamespacedId("redstone_wall_torch"), 249, 50, 28, 255);
  setLightColor(new NamespacedId("soul_campfire"), 51, 204, 255, 255);
  setLightColor(new NamespacedId("verdant_froglight"), 99, 229, 60, 255);
  setLightColor(new NamespacedId("torch"), 255, 119, 0, 255);
  setLightColor(new NamespacedId("wall_torch"), 255, 119, 0, 255);
  setLightColor(new NamespacedId("nether_portal"), 100, 0, 255, 255);
  setLightColor(new NamespacedId("small_amethyst_bud"), 184, 88, 221, 255);
  setLightColor(new NamespacedId("medium_amethyst_bud"), 184, 88, 221, 255);
  setLightColor(new NamespacedId("large_amethyst_bud"), 184, 88, 221, 255);
  setLightColor(new NamespacedId("amethyst_cluster"), 184, 88, 221, 255);
  const glassOpacity = 255;
  setLightColor(new NamespacedId("tinted_glass"), 50, 38, 56, glassOpacity);
  setLightColor(
    new NamespacedId("white_stained_glass"),
    255,
    255,
    255,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("white_stained_glass_pane"),
    255,
    255,
    255,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("light_gray_stained_glass"),
    153,
    153,
    153,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("light_gray_stained_glass_pane"),
    153,
    153,
    153,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("gray_stained_glass"),
    76,
    76,
    76,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("gray_stained_glass_pane"),
    76,
    76,
    76,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("black_stained_glass"),
    25,
    25,
    25,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("black_stained_glass_pane"),
    25,
    25,
    25,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("brown_stained_glass"),
    102,
    76,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("brown_stained_glass_pane"),
    102,
    76,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("red_stained_glass"),
    153,
    51,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("red_stained_glass_pane"),
    153,
    51,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("orange_stained_glass"),
    216,
    127,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("orange_stained_glass_pane"),
    216,
    127,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("yellow_stained_glass"),
    229,
    229,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("yellow_stained_glass_pane"),
    229,
    229,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("lime_stained_glass"),
    127,
    204,
    25,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("lime_stained_glass_pane"),
    127,
    204,
    25,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("green_stained_glass"),
    102,
    127,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("green_stained_glass_pane"),
    102,
    127,
    51,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("cyan_stained_glass"),
    76,
    127,
    153,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("cyan_stained_glass_pane"),
    76,
    127,
    153,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("light_blue_stained_glass"),
    102,
    153,
    216,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("light_blue_stained_glass_pane"),
    102,
    153,
    216,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("blue_stained_glass"),
    51,
    76,
    178,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("blue_stained_glass_pane"),
    51,
    76,
    178,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("purple_stained_glass"),
    127,
    63,
    178,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("purple_stained_glass_pane"),
    127,
    63,
    178,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("magenta_stained_glass"),
    178,
    76,
    216,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("magenta_stained_glass_pane"),
    178,
    76,
    216,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("pink_stained_glass"),
    242,
    127,
    165,
    glassOpacity
  );
  setLightColor(
    new NamespacedId("pink_stained_glass_pane"),
    242,
    127,
    165,
    glassOpacity
  );
}

// pack.ts
var maxPointLights = 64;
var lightRadius = 32;
var cascades = 4;
var shadowRes = 1592;
var cloudTexRead;
var cloudTexWrite;
var cloudTexA;
var cloudTexB;
var ssrTexRead;
var ssrTexWrite;
var ssrTexA;
var ssrTexB;
var globalIlluminationTexRead;
var globalIlluminationTexWrite;
var globalIlluminationTexA;
var globalIlluminationTexB;
var cloudyFogTexRead;
var cloudyFogTexWrite;
var cloudyFogTexA;
var cloudyFogTexB;
function configureRenderer(renderer) {
  renderer.disableShade = true;
  renderer.sunPathRotation = 40;
  renderer.shadow.resolution = shadowRes;
  renderer.shadow.entityCascadeCount = 1;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = cascades;
  renderer.render.waterOverlay = false;
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
function beginFrame(state) {
  cloudTexWrite.pointTo(state.currentFrame() % 2 == 0 ? cloudTexA : cloudTexB);
  cloudTexRead.pointTo(state.currentFrame() % 2 == 0 ? cloudTexB : cloudTexA);
  ssrTexWrite.pointTo(state.currentFrame() % 2 == 0 ? ssrTexA : ssrTexB);
  ssrTexRead.pointTo(state.currentFrame() % 2 == 0 ? ssrTexB : ssrTexA);
  globalIlluminationTexWrite.pointTo(
    state.currentFrame() % 2 == 0 ? globalIlluminationTexA : globalIlluminationTexB
  );
  globalIlluminationTexRead.pointTo(
    state.currentFrame() % 2 == 0 ? globalIlluminationTexB : globalIlluminationTexA
  );
  cloudyFogTexWrite.pointTo(
    state.currentFrame() % 2 == 0 ? cloudyFogTexA : cloudyFogTexB
  );
  cloudyFogTexRead.pointTo(
    state.currentFrame() % 2 == 0 ? cloudyFogTexB : cloudyFogTexA
  );
}
function configurePipeline(pipeline) {
  pipeline.addTag(0, new NamespacedId("minecraft", "leaves"));
  defineGlobally("TAG_LEAVES", "0");
  defineGlobally("LIGHT_RADIUS", lightRadius);
  defineGlobally("MAX_LIGHTS", maxPointLights);
  const lightListBinSize = 8;
  defineGlobally("LIGHT_LIST_BIN_SIZE", lightListBinSize);
  const lightListVolumeSize = 128;
  defineGlobally("LIGHT_LIST_VOLUME_SIZE", lightListVolumeSize);
  const lightListBinCount = Math.pow(lightListVolumeSize / lightListBinSize, 3) >> 0;
  const lightLightBinsPerAxis = lightListVolumeSize / lightListBinSize;
  defineGlobally("LIGHT_LIST_BIN_COUNT_AXIS", lightLightBinsPerAxis);
  defineGlobally("LIGHT_LIST_BIN_COUNT", lightListBinCount);
  const maxLightsPerBin = 64;
  defineGlobally("MAX_LIGHTS_PER_BIN", maxLightsPerBin);
  defineGlobally("CASCADES", cascades.toString());
  const lightLists = pipeline.createBuffer(
    (maxLightsPerBin + 2) * lightListBinCount * 4,
    false
  );
  const cameraData = pipeline.createBuffer(16, false);
  defineGlobally("EMISSION_STRENGTH", 10);
  const screenSetup = pipeline.forStage(Stage.SCREEN_SETUP);
  const preRender = pipeline.forStage(Stage.PRE_RENDER);
  const preTranslucent = pipeline.forStage(Stage.PRE_TRANSLUCENT);
  const postRender = pipeline.forStage(Stage.POST_RENDER);
  const sceneData = pipeline.createBuffer(32, false);
  const blueNoiseTex = pipeline.importRawTexture("blue_noise_tex", "textures/stbn.bin").width(128).height(128).depth(64).format(Format.RGB8).type(PixelType.UNSIGNED_BYTE).blur(false).clamp(false).load();
  const whiteNoiseTex = pipeline.importPNGTexture(
    "noise_tex",
    "textures/noise.png",
    true,
    false
  );
  const debugTex = pipeline.createImageTexture("_debug_tex", "debug").format(Format.RGBA8).width(screenWidth).height(screenHeight).clear(true).build();
  const previousSolidDepthTex = pipeline.createTexture("previousSolidDepthTex").format(Format.R32F).clear(false).build();
  const previousMainDepthTex = pipeline.createTexture("previousMainDepthTex").format(Format.R32F).clear(false).build();
  const sunTransmittanceLUT = pipeline.createImageTexture("sun_transmittance_lut_tex", "sun_transmittance_lut").format(Format.RGBA16F).width(256).height(64).clear(false).build();
  const multipleScatteringLUT = pipeline.createImageTexture(
    "multiple_scattering_lut_tex",
    "multiple_scattering_lut"
  ).format(Format.RGBA16F).width(32).height(32).clear(false).build();
  const skyViewLUT = pipeline.createImageTexture("sky_view_lut_tex", "sky_view_lut").format(Format.RGBA16F).width(200).height(200).clear(true).mipmap(false).build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)");
  const atmosphericFogLUT = pipeline.createImageTexture("atmospheric_fog_lut_tex", "atmospheric_fog_lut").format(Format.RGBA16F).width(32).height(32).depth(64).clear(false).build();
  screenSetup.createCompute("generate_sun_transmittance_lut").location("program/atmosphere/generate_sun_transmittance_lut.csh").workGroups(32, 8, 1).compile();
  screenSetup.barrier(IMAGE_BIT);
  screenSetup.createCompute("generate_multiple_scattering_lut").location("program/atmosphere/generate_multiple_scattering_lut.csh").workGroups(4, 4, 1).compile();
  preRender.barrier(IMAGE_BIT);
  preRender.createCompute("generate_sky_view_lut").location("program/atmosphere/generate_sky_view_lut.csh").workGroups(25, 25, 1).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preRender.barrier(IMAGE_BIT);
  preRender.createCompute("generate_atmospheric_fog_lut").location("program/atmosphere/generate_atmospheric_fog_lut.csh").workGroups(4, 4, 8).compile();
  preRender.barrier(IMAGE_BIT);
  const cloudShapeTex = pipeline.createImageTexture("cloud_shape_tex", "cloud_shape").format(Format.R16).width(128).height(128).depth(128).clear(false).build();
  screenSetup.createCompute("generate_cloud_shape").location("program/render_setup/generate_cloud_shape.csh").workGroups(32, 32, 32).compile();
  const cloudDetailTex = pipeline.createImageTexture("cloud_detail_tex", "cloud_detail").format(Format.R16).width(32).height(32).depth(32).clear(false).build();
  screenSetup.createCompute("generate_cloud_detail").location("program/render_setup/generate_cloud_detail.csh").workGroups(8, 8, 8).compile();
  const cloudWeatherTex = pipeline.createImageTexture("cloud_weather_tex", "cloud_weather").format(Format.RGBA16).width(512).height(512).clear(false).build();
  preRender.createCompute("generate_cloud_weather").location("program/render_setup/generate_cloud_weather.csh").workGroups(64, 64, 1).compile();
  preRender.barrier(IMAGE_BIT);
  const cloudSpheremapLUTTex = pipeline.createImageTexture("cloud_spheremap_tex", "cloud_spheremap").format(Format.RGBA16F).width(512).height(512).clear(false).build();
  const cloudShadowTex = pipeline.createTexture("cloud_shadow_tex").format(Format.R16).width(2048).height(2048).build();
  preTranslucent.createComposite("cloud_shadow_map").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/generate_cloud_shadow_map.fsh").target(0, cloudShadowTex).compile();
  preRender.createCompute("generate_cloud_spheremap").location("program/render_setup/generate_cloud_spheremap.csh").workGroups(32, 32, 1).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preRender.barrier(IMAGE_BIT);
  const skyIrradianceLUT = pipeline.createImageTexture("sky_irradiance_lut_tex", "sky_irradiance_lut").format(Format.RGBA16F).width(32).height(32).clear(false).build();
  preRender.createCompute("generate_sky_irradiance_lut").location("program/render_setup/generate_sky_irradiance_lut.csh").workGroups(4, 4, 1).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preRender.createCompute("clearLightLists").location("program/render_setup/clear_light_lists.csh").workGroups(Math.ceil(lightListBinCount / 64), 1, 1).ssbo(0, lightLists).define("LIGHT_LIST_BINDING", "0").compile();
  preRender.barrier(SSBO_BIT);
  preRender.createCompute("generateLightLists").location("program/render_setup/generate_light_lists.csh").workGroups(Math.ceil(maxPointLights / 64), 1, 1).ssbo(0, lightLists).define("LIGHT_LIST_BINDING", "0").compile();
  preRender.barrier(SSBO_BIT);
  preRender.createCompute("propagateLightLists").location("program/render_setup/propagate_light_lists.csh").workGroups(
    Math.ceil(lightLightBinsPerAxis / 4),
    Math.ceil(lightLightBinsPerAxis / 4),
    Math.ceil(lightLightBinsPerAxis / 4)
  ).ssbo(0, lightLists).define("LIGHT_LIST_BINDING", "0").compile();
  const shadowColorTex = pipeline.createArrayTexture("shadow_color_tex").width(shadowRes).height(shadowRes).slices(cascades).build();
  pipeline.createObjectShader("shadow", Usage.SHADOW).vertex("program/geometry/shadow.vsh").fragment("program/geometry/shadow.fsh").target(0, shadowColorTex).blendOff(0).compile();
  pipeline.createObjectShader("point_shadow", Usage.POINT).vertex("program/geometry/point_shadow.vsh").fragment("program/geometry/point_shadow.fsh").compile();
  const gbufferTex1 = pipeline.createTexture("gbuffer_tex_1").format(Format.RGBA16).clear(true).build();
  const gbufferTex2 = pipeline.createTexture("gbuffer_tex_2").format(Format.RGBA16).clear(true).build();
  const deferredGbuffers = [
    Usage.TERRAIN_SOLID,
    Usage.TERRAIN_CUTOUT,
    Usage.ENTITY_SOLID,
    Usage.ENTITY_CUTOUT,
    Usage.BLOCK_ENTITY,
    Usage.PARTICLES,
    Usage.EMISSIVE,
    Usage.HAND
  ];
  const forwardGbuffers = [
    Usage.TERRAIN_TRANSLUCENT,
    Usage.ENTITY_TRANSLUCENT,
    Usage.BLOCK_ENTITY_TRANSLUCENT,
    Usage.PARTICLES_TRANSLUCENT,
    Usage.TRANSLUCENT_HAND,
    Usage.TEXTURED,
    Usage.BASIC,
    Usage.TEXT
  ];
  const discardGbuffers = [
    Usage.CLOUDS,
    Usage.SKYBOX,
    Usage.SKY_TEXTURES,
    Usage.WEATHER
  ];
  deferredGbuffers.forEach((program) => {
    pipeline.createObjectShader("terrain", program).vertex("program/geometry/opaque.vsh").fragment("program/geometry/opaque.fsh").target(0, gbufferTex1).target(1, gbufferTex2).compile();
  });
  discardGbuffers.forEach((program) => {
    pipeline.createObjectShader("clouds", program).vertex("program/geometry/discard.vsh").fragment("program/geometry/discard.fsh").compile();
  });
  const translucentTex = pipeline.createTexture("translucent_tex").format(Format.RGBA16F).clear(true).clearColor(0, 0, 0, 0).build();
  const shadowTex = pipeline.createTexture("shadow_tex").format(Format.RGBA8).clear(true).build();
  forwardGbuffers.forEach((program) => {
    pipeline.createObjectShader("water", program).vertex("program/geometry/translucent.vsh").fragment("program/geometry/translucent.fsh").target(0, translucentTex).target(1, gbufferTex1).target(2, gbufferTex2).target(3, shadowTex).blendOff(1).blendOff(2).blendOff(3).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  });
  const causticsTex = pipeline.createArrayTexture("caustics_tex").format(Format.R8).width(shadowRes).height(shadowRes).slices(cascades).build();
  preTranslucent.createArrayComposite("caustics").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/generate_caustics.fsh").target(0, causticsTex).build();
  preTranslucent.createComposite("opaque_shadowing").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_shadowing.fsh").target(0, shadowTex).compile();
  const sceneTex = new FlippableTexture("scene_tex").format(Format.RGBA16F).clear(false).mipmap(true).build(pipeline);
  preTranslucent.createComposite("sky").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/render_sky.fsh").target(0, sceneTex.target).compile();
  const diffuseTex = pipeline.createTexture("diffuse_tex").format(Format.R11F_G11F_B10F).clear(false).build();
  globalIlluminationTexA = pipeline.createTexture("global_illumination_tex_a").format(Format.RGBA16F).clear(false).build();
  globalIlluminationTexB = pipeline.createTexture("global_illumination_tex_b").format(Format.RGBA16F).clear(false).build();
  globalIlluminationTexWrite = pipeline.createTextureReference(
    "global_illumination_tex_w",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  globalIlluminationTexRead = pipeline.createTextureReference(
    "global_illumination_tex",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  preTranslucent.createComposite("global_illumination").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/ssgi.fsh").target(0, globalIlluminationTexWrite).ssbo(0, sceneData).compile();
  ssrTexA = pipeline.createTexture("ssr_tex_a").format(Format.RGBA16F).clear(false).build();
  ssrTexB = pipeline.createTexture("ssr_tex_b").format(Format.RGBA16F).clear(false).build();
  ssrTexWrite = pipeline.createTextureReference(
    "ssr_tex_w",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  ssrTexRead = pipeline.createTextureReference(
    "ssr_tex",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  preTranslucent.createComposite("opaque_ssr").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_ssr.fsh").target(0, ssrTexWrite).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preTranslucent.createComposite("opaque_shading").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_shading.fsh").target(0, sceneTex.target).target(1, diffuseTex).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preTranslucent.createComposite("opaque_point_lights").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_point_lights.fsh").target(0, sceneTex.target).target(1, diffuseTex).ssbo(0, lightLists).define("LIGHT_LIST_BINDING", "0").compile();
  cloudTexA = pipeline.createTexture("cloud_tex_a").format(Format.RGBA16F).width(Math.floor(screenWidth * 0.5)).height(Math.floor(screenHeight * 0.5)).clear(false).build();
  cloudTexB = pipeline.createTexture("cloud_tex_b").format(Format.RGBA16F).width(Math.floor(screenWidth * 0.5)).height(Math.floor(screenHeight * 0.5)).clear(false).build();
  cloudTexWrite = pipeline.createTextureReference(
    "cloud_tex_w",
    null,
    Math.floor(screenWidth * 0.5),
    Math.floor(screenHeight * 0.5),
    1,
    Format.RGBA16F
  );
  cloudTexRead = pipeline.createTextureReference(
    "cloud_tex",
    null,
    Math.floor(screenWidth * 0.5),
    Math.floor(screenHeight * 0.5),
    1,
    Format.RGBA16F
  );
  preTranslucent.createComposite("render_clouds").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/render_clouds.fsh").target(0, cloudTexWrite).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  preTranslucent.createComposite("blend_clouds").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/blend_clouds.fsh").target(0, sceneTex.target).compile();
  postRender.createComposite("water_fog_outside_water").vertex("program/fullscreen_pass.vsh").fragment("program/post/water_fog.fsh").target(0, sceneTex.target).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").define("CONDITION", "is_water && !in_water").define("START_POS", "translucent_player_pos").define("END_POS", "opaque_player_pos").compile();
  sceneTex.flip();
  postRender.createComposite("blend_translucents").vertex("program/fullscreen_pass.vsh").fragment("program/post/translucent_shading.fsh").target(0, sceneTex.target).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  sceneTex.unflip();
  cloudyFogTexA = pipeline.createTexture("cloudy_fog_tex_a").format(Format.RGBA16F).clear(false).build();
  cloudyFogTexB = pipeline.createTexture("cloudy_fog_tex_b").format(Format.RGBA16F).clear(false).build();
  cloudyFogTexWrite = pipeline.createTextureReference(
    "cloudy_fog_tex_w",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  cloudyFogTexRead = pipeline.createTextureReference(
    "cloudy_fog_tex",
    null,
    screenWidth,
    screenHeight,
    1,
    Format.RGBA16F
  );
  postRender.createComposite("render_cloudy_fog").vertex("program/fullscreen_pass.vsh").fragment("program/post/render_cloudy_fog.fsh").target(0, cloudyFogTexWrite).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").compile();
  postRender.createComposite("blend_cloudy_fog").vertex("program/fullscreen_pass.vsh").fragment("program/post/blend_cloudy_fog.fsh").target(0, sceneTex.target).compile();
  postRender.createComposite("water_fog_inside_water").vertex("program/fullscreen_pass.vsh").fragment("program/post/water_fog.fsh").target(0, sceneTex.target).ssbo(0, sceneData).define("SCENE_DATA_BINDING", "0").define("CONDITION", "in_water").define("START_POS", "vec3(0.0)").define("END_POS", "translucent_player_pos").compile();
  postRender.createComposite("luminance_alpha").vertex("program/fullscreen_pass.vsh").fragment("program/post/write_luminance_to_alpha.fsh").target(0, sceneTex.target).compile();
  postRender.generateMips(sceneTex.target);
  postRender.createCompute("fetch_camera_data").workGroups(1, 1, 1).location("program/post/fetch_camera_data.csh").ssbo(0, cameraData).define("CAMERA_DATA_BINDING", "0").compile();
  postRender.createComposite("exposure").vertex("program/fullscreen_pass.vsh").fragment("program/post/exposure.fsh").target(0, sceneTex.target).ssbo(0, cameraData).define("CAMERA_DATA_BINDING", "0").compile();
  const DoFCoCTex = pipeline.createTexture("dof_coc_tex").format(Format.R16F).build();
  postRender.createComposite("dof_coc").vertex("program/fullscreen_pass.vsh").fragment("program/post/dof_coc.fsh").target(0, DoFCoCTex).compile();
  const DoFTex = pipeline.createTexture("dof_tex").format(Format.RGB16F).build();
  postRender.createComposite("dof_blur").vertex("program/fullscreen_pass.vsh").fragment("program/post/dof_blur.fsh").target(0, DoFTex).compile();
  const bloomTex = pipeline.createTexture("bloom_tex").format(Format.RGBA16F).clear(true).mipmap(true).build();
  for (let i = 0; i < 5; i++) {
    postRender.createComposite(`bloom_downsample${i}-${i + 1}`).vertex("program/fullscreen_pass.vsh").fragment("program/post/bloom_downsample.fsh").target(0, bloomTex, i + 1).define("BLOOM_INDEX", i.toString()).compile();
  }
  for (let i = 5; i > 0; i -= 1) {
    postRender.createComposite(`bloom_upsample${i}-${i - 1}`).vertex("program/fullscreen_pass.vsh").fragment("program/post/bloom_upsample.fsh").target(0, bloomTex, i - 1).define("BLOOM_INDEX", i.toString()).compile();
  }
  postRender.createComposite("copy_previous_main_depth").vertex("program/fullscreen_pass.vsh").fragment("program/buffer_copy.fsh").target(0, previousMainDepthTex).define("SAMPLE_BUFFER", "mainDepthTex").compile();
  postRender.createComposite("copy_previous_solid_depth").vertex("program/fullscreen_pass.vsh").fragment("program/buffer_copy.fsh").target(0, previousSolidDepthTex).define("SAMPLE_BUFFER", "solidDepthTex").compile();
  screenSetup.end();
  preRender.end();
  preTranslucent.end();
  postRender.end();
  let tonyMcMapFaceTex = pipeline.importRawTexture("tony_mc_mapface_tex", "textures/tony_mc_mapface.bin").blur(true).clamp(true).width(48).height(48).depth(48).type(PixelType.FLOAT).format(Format.RGBA32F).load();
  pipeline.createCombinationPass("program/combination.fsh").ssbo(0, lightLists).define("LIGHT_LIST_BINDING", "0").compile();
}
export {
  beginFrame,
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
