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
  build() {
    this.textureA = new Texture(this.name + "_a");
    this.textureB = new Texture(this.name + "_b");
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
    if (this._imageName) {
      this.textureA.imageName(this._imageName + "_a");
      this.textureB.imageName(this._imageName + "_b");
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
    print("sampler is now " + this.sampler);
    print(
      "target is now " + this.name + (this.flipped != this.unflipped ? "_b" : "_a")
    );
    print("---");
  }
  // Causes the rendertarget to point to the same buffer as the sampler until the next flip operation. This is the default state.
  unflip() {
    if (this.unflipped) return;
    this.flipped = !this.flipped;
    this.unflipped = true;
    defineGlobally(this.name, this.sampler);
    print("sampler is now " + this.sampler);
    print(
      "target is now " + this.name + (this.flipped != this.unflipped ? "_b" : "_a")
    );
    print("---");
  }
};

// pack.ts
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
  setLightColor(new NamespacedId("white_stained_glass"), 255, 255, 255, glassOpacity);
  setLightColor(new NamespacedId("white_stained_glass_pane"), 255, 255, 255, glassOpacity);
  setLightColor(new NamespacedId("light_gray_stained_glass"), 153, 153, 153, glassOpacity);
  setLightColor(new NamespacedId("light_gray_stained_glass_pane"), 153, 153, 153, glassOpacity);
  setLightColor(new NamespacedId("gray_stained_glass"), 76, 76, 76, glassOpacity);
  setLightColor(new NamespacedId("gray_stained_glass_pane"), 76, 76, 76, glassOpacity);
  setLightColor(new NamespacedId("black_stained_glass"), 25, 25, 25, glassOpacity);
  setLightColor(new NamespacedId("black_stained_glass_pane"), 25, 25, 25, glassOpacity);
  setLightColor(new NamespacedId("brown_stained_glass"), 102, 76, 51, glassOpacity);
  setLightColor(new NamespacedId("brown_stained_glass_pane"), 102, 76, 51, glassOpacity);
  setLightColor(new NamespacedId("red_stained_glass"), 153, 51, 51, glassOpacity);
  setLightColor(new NamespacedId("red_stained_glass_pane"), 153, 51, 51, glassOpacity);
  setLightColor(new NamespacedId("orange_stained_glass"), 216, 127, 51, glassOpacity);
  setLightColor(new NamespacedId("orange_stained_glass_pane"), 216, 127, 51, glassOpacity);
  setLightColor(new NamespacedId("yellow_stained_glass"), 229, 229, 51, glassOpacity);
  setLightColor(new NamespacedId("yellow_stained_glass_pane"), 229, 229, 51, glassOpacity);
  setLightColor(new NamespacedId("lime_stained_glass"), 127, 204, 25, glassOpacity);
  setLightColor(new NamespacedId("lime_stained_glass_pane"), 127, 204, 25, glassOpacity);
  setLightColor(new NamespacedId("green_stained_glass"), 102, 127, 51, glassOpacity);
  setLightColor(new NamespacedId("green_stained_glass_pane"), 102, 127, 51, glassOpacity);
  setLightColor(new NamespacedId("cyan_stained_glass"), 76, 127, 153, glassOpacity);
  setLightColor(new NamespacedId("cyan_stained_glass_pane"), 76, 127, 153, glassOpacity);
  setLightColor(new NamespacedId("light_blue_stained_glass"), 102, 153, 216, glassOpacity);
  setLightColor(new NamespacedId("light_blue_stained_glass_pane"), 102, 153, 216, glassOpacity);
  setLightColor(new NamespacedId("blue_stained_glass"), 51, 76, 178, glassOpacity);
  setLightColor(new NamespacedId("blue_stained_glass_pane"), 51, 76, 178, glassOpacity);
  setLightColor(new NamespacedId("purple_stained_glass"), 127, 63, 178, glassOpacity);
  setLightColor(new NamespacedId("purple_stained_glass_pane"), 127, 63, 178, glassOpacity);
  setLightColor(new NamespacedId("magenta_stained_glass"), 178, 76, 216, glassOpacity);
  setLightColor(new NamespacedId("magenta_stained_glass_pane"), 178, 76, 216, glassOpacity);
  setLightColor(new NamespacedId("pink_stained_glass"), 242, 127, 165, glassOpacity);
  setLightColor(new NamespacedId("pink_stained_glass_pane"), 242, 127, 165, glassOpacity);
}
function defineBoolGlobally(define) {
  if (getBoolSetting(define)) {
    defineGlobally(define, 1);
  }
}
function setupShader(dimension) {
  worldSettings.pointNearPlane = 0.1;
  worldSettings.pointFarPlane = 52;
  defineBoolGlobally("BLOOM_ENABLE");
  defineBoolGlobally("TEMPORAL_FILTER_ENABLE");
  defineGlobally("SHADOW_SAMPLES", getIntSetting("SHADOW_SAMPLES"));
  defineBoolGlobally("SSGI_ENABLE");
  defineBoolGlobally("DEBUG_ENABLE");
  defineBoolGlobally("SHADOW_POINT_LIGHT");
  defineGlobally("POINT_NEAR_PLANE", worldSettings.pointNearPlane);
  defineGlobally("POINT_FAR_PLANE", worldSettings.pointFarPlane);
  enableShadows(1024, 4);
  setLightColors();
  const maxMip = Math.floor(Math.log2(Math.max(screenWidth, screenHeight)));
  worldSettings.ambientOcclusionLevel = 0;
  worldSettings.disableShade = true;
  worldSettings.renderEntityShadow = false;
  worldSettings.sunPathRotation = 40;
  worldSettings.renderSun = false;
  worldSettings.renderWaterOverlay = false;
  const sceneData = new GPUBuffer(32).clear(true).build();
  const blueNoiseTex = new PNGTexture("blueNoiseTex", "textures/blueNoise.png", false, true);
  const perlinNoiseTex = new PNGTexture("perlinNoiseTex", "textures/perlinNoise.png", true, true);
  const worleyNoiseTex = new PNGTexture("worleyNoiseTex", "textures/worleyNoise.png", true, true);
  const cloudShapeNoiseTex = new RawTexture("cloudShapeNoiseTex", "textures/cloudNoiseShape.bin").width(128).height(128).depth(128).type(PixelType.UNSIGNED_BYTE).format(Format.RGBA8).blur(true).build();
  const cloudErosionNoiseTex = new RawTexture("cloudErosionNoiseTex", "textures/cloudNoiseErosion.bin").width(32).height(32).depth(32).type(PixelType.UNSIGNED_BYTE).format(Format.RGB8).blur(true).build();
  const cloudHeightGradientTex = new PNGTexture("cloudHeightGradientTex", "textures/cloudHeightGradient.png", false, true);
  const debugTex = new Texture("debugTex").format(Format.RGBA8).imageName("debugImg").width(screenWidth).height(screenHeight).clear(true).clearColor(0, 0, 0, 0).build();
  const previousSceneTex = new Texture("previousSceneTex").format(Format.RGB16F).clear(false).mipmap(true).build();
  const previousDepthTex = new Texture("previousDepthTex").format(Format.RG16).clear(false).mipmap(true).build();
  const sunTransmittanceLUT = new Texture("sunTransmittanceLUTTex").format(Format.RGBA16F).imageName("sunTransmittanceLUT").width(256).height(64).clear(false).build();
  registerShader(
    Stage.SCREEN_SETUP,
    new Compute("generateSunTransmittanceLUT").location("program/sky/generateSunTransmittanceLUT.csh").workGroups(32, 8, 1).build()
  );
  const multipleScatteringLUT = new Texture("multipleScatteringLUTTex").format(Format.RGBA16F).imageName("multipleScatteringLUT").width(32).height(32).clear(false).build();
  registerShader(
    Stage.SCREEN_SETUP,
    new Compute("generateMultipleScatteringLUT").location("program/sky/generateMultipleScatteringLUT.csh").workGroups(4, 4, 1).build()
  );
  const skyViewLUT = new Texture("skyViewLUTTex").format(Format.RGBA16F).imageName("skyViewLUT").width(200).height(200).clear(true).mipmap(true).build();
  registerShader(
    Stage.PRE_RENDER,
    new Compute("generateSkyViewLUT").location("program/sky/generateSkyViewLUT.csh").workGroups(25, 25, 1).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.PRE_RENDER,
    new GenerateMips(skyViewLUT)
  );
  registerShader(
    Stage.PRE_RENDER,
    new Compute("getSkylightColor").location("program/sky/getSkylightColor.csh").workGroups(1, 1, 1).ssbo(0, sceneData).build()
  );
  registerShader(Stage.PRE_RENDER, new MemoryBarrier(SSBO_BIT));
  const cloudSkyLUT = new Texture("cloudSkyLUTTex").format(Format.RGBA16F).width(512).height(512).clear(false).mipmap(true).build();
  registerShader(
    Stage.PRE_RENDER,
    new Composite("renderCloudSKYLUT").vertex("program/fullscreen.vsh").fragment("program/prepare/renderCloudSkyLUT.fsh").target(0, cloudSkyLUT).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.PRE_RENDER,
    new GenerateMips(previousSceneTex)
  );
  const voxelMapWidth = 256;
  const voxelMapHeight = 128;
  defineGlobally("VOXEL_MAP_SIZE", `vec3(${voxelMapWidth}, ${voxelMapHeight}, ${voxelMapWidth})`);
  const floodfillVoxelMap1 = new Texture("floodFillVoxelMapTex1").format(Format.RGBA16F).imageName("floodFillVoxelMap1").clear(false).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  const floodfillVoxelMap2 = new Texture("floodFillVoxelMapTex2").format(Format.RGBA16F).imageName("floodFillVoxelMap2").clear(false).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  const voxelMap = new Texture("voxelMapTex").format(Format.R32UI).imageName("voxelMap").clear(true).clearColor(0, 0, 0, 0).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  const shadowColorTex = new ArrayTexture("shadowColorTex").format(Format.RGBA8).clear(true).build();
  const shadowNormalTex = new ArrayTexture("shadowNormalTex").format(Format.RGBA8).clear(true).clearColor(0, 0, 0, 0).build();
  const shadowPositionTex = new ArrayTexture("shadowPositionTex").format(Format.RGB16F).clear(true).build();
  const shadowMaskTex = new ArrayTexture("shadowMaskTex").format(Format.R8UI).clear(true).build();
  registerShader(
    new ObjectShader("shadow", Usage.SHADOW).vertex("program/gbuffer/shadow.vsh").fragment("program/gbuffer/shadow.fsh").target(0, shadowColorTex).target(1, shadowNormalTex).target(2, shadowPositionTex).target(3, shadowMaskTex).blendFunc(0, Func.ONE, Func.ZERO, Func.ONE, Func.ZERO).blendFunc(1, Func.ONE, Func.ZERO, Func.ONE, Func.ZERO).blendFunc(2, Func.ONE, Func.ZERO, Func.ONE, Func.ZERO).build()
  );
  if (getBoolSetting("SHADOW_POINT_LIGHT")) {
    registerShader(
      new ObjectShader("point", Usage.POINT).vertex("program/gbuffer/pointShadow.vsh").fragment("program/gbuffer/pointShadow.fsh").build()
    );
  }
  registerShader(
    Stage.POST_SHADOW,
    new Compute("floodfillPropagate").location("program/composite/floodfillPropagate.csh").workGroups(voxelMapWidth / 4, voxelMapHeight / 4, voxelMapWidth / 4).build()
  );
  registerShader(Stage.POST_SHADOW, new MemoryBarrier(IMAGE_BIT));
  const sceneTex = new FlippableTexture("sceneTex").format(Format.RGB16F).clear(true).clearColor(0, 0, 0, 1).build();
  const translucentsTex = new Texture("translucentsTex").format(Format.RGBA16F).clear(true).clearColor(0, 0, 0, 0).build();
  const gbufferDataTex1 = new Texture("gbufferDataTex1").format(Format.RGBA16).clear(true).build();
  const gbufferDataTex2 = new Texture("gbufferDataTex2").format(Format.RGBA16).clear(true).build();
  registerShader(
    new ObjectShader("sky", Usage.SKYBOX).vertex("program/gbuffer/sky.vsh").fragment("program/gbuffer/sky.fsh").define("SKY_BASIC", "1").target(0, sceneTex.target).build()
  );
  registerShader(
    new ObjectShader("sky", Usage.SKY_TEXTURES).vertex("program/gbuffer/sky.vsh").fragment("program/gbuffer/sky.fsh").define("SKY_TEXTURED", "2").target(0, sceneTex.target).build()
  );
  const deferredGbuffers = [
    Usage.TERRAIN_SOLID,
    Usage.TERRAIN_CUTOUT,
    Usage.ENTITY_SOLID,
    Usage.ENTITY_CUTOUT,
    Usage.BLOCK_ENTITY,
    Usage.PARTICLES,
    Usage.EMISSIVE
  ];
  const forwardGbuffers = [
    Usage.TERRAIN_TRANSLUCENT,
    Usage.ENTITY_TRANSLUCENT,
    Usage.BLOCK_ENTITY_TRANSLUCENT,
    Usage.PARTICLES_TRANSLUCENT,
    Usage.HAND,
    Usage.TRANSLUCENT_HAND,
    Usage.TEXTURED,
    Usage.BASIC,
    Usage.TEXT
  ];
  deferredGbuffers.forEach((program) => {
    registerShader(
      new ObjectShader("terrain", program).vertex("program/gbuffer/main.vsh").fragment("program/gbuffer/main.fsh").target(0, sceneTex.target).target(1, gbufferDataTex1).target(2, gbufferDataTex2).ssbo(0, sceneData).build()
    );
  });
  forwardGbuffers.forEach((program) => {
    registerShader(
      new ObjectShader("terrain", program).vertex("program/gbuffer/main.vsh").fragment("program/gbuffer/main.fsh").target(0, translucentsTex).target(1, gbufferDataTex1).target(2, gbufferDataTex2).blendFunc(1, Func.ONE, Func.ZERO, Func.ONE, Func.ZERO).blendFunc(2, Func.ONE, Func.ZERO, Func.ONE, Func.ZERO).define("FORWARD_LIGHTING", "1").ssbo(0, sceneData).build()
    );
  });
  registerShader(
    new ObjectShader("clouds", Usage.CLOUDS).vertex("program/gbuffer/discard.vsh").fragment("program/gbuffer/discard.fsh").build()
  );
  registerShader(Stage.PRE_TRANSLUCENT, new MemoryBarrier(IMAGE_BIT));
  const globalIlluminationTex = new Texture("globalIlluminationTex").format(Format.R11F_G11F_B10F).clear(false).width(parseInt(screenWidth * 0.5)).height(parseInt(screenHeight * 0.5)).build();
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("deferredShading").vertex("program/fullscreen.vsh").fragment("program/composite/deferredShading.fsh").target(0, sceneTex.target).ssbo(0, sceneData).build()
  );
  if (getBoolSetting("SSGI_ENABLE")) {
    registerShader(
      Stage.PRE_TRANSLUCENT,
      new Composite("globalIllumination").vertex("program/fullscreen.vsh").fragment("program/composite/SSGI.fsh").target(0, globalIlluminationTex).ssbo(0, sceneData).build()
    );
    registerShader(
      Stage.PRE_TRANSLUCENT,
      new Composite("compositeGlobalIllumination").vertex("program/fullscreen.vsh").fragment("program/composite/compositeSSGI.fsh").target(0, sceneTex.target).ssbo(0, sceneData).build()
    );
  }
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("compositeSky").vertex("program/fullscreen.vsh").fragment("program/composite/compositeSky.fsh").target(0, sceneTex.target).build()
  );
  const cloudScatterTex = new FlippableTexture("cloudScatterTex").format(Format.RGB16F).clear(false).width(parseInt(screenWidth)).height(parseInt(screenHeight)).mipmap(true).build();
  const cloudTransmitTex = new FlippableTexture("cloudTransmitTex").format(Format.RGB16F).clear(false).width(parseInt(screenWidth)).height(parseInt(screenHeight)).mipmap(true).build();
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("renderClouds").vertex("program/fullscreen.vsh").fragment("program/composite/renderClouds.fsh").target(0, cloudScatterTex.target).target(1, cloudTransmitTex.target).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("compositeClouds").vertex("program/fullscreen.vsh").fragment("program/composite/compositeClouds.fsh").target(0, sceneTex.target).ssbo(0, sceneData).build()
  );
  sceneTex.flip();
  registerShader(
    Stage.POST_RENDER,
    new Composite("compositeTranslucents").vertex("program/fullscreen.vsh").fragment("program/composite/compositeTranslucents.fsh").target(0, sceneTex.target).ssbo(0, sceneData).build()
  );
  sceneTex.unflip();
  registerShader(
    Stage.POST_RENDER,
    new Composite("cloudyFog").vertex("program/fullscreen.vsh").fragment("program/composite/cloudyFog.fsh").target(0, sceneTex.target).ssbo(0, sceneData).build()
  );
  if (getBoolSetting("DOF_ENABLE")) {
    const DoFCoCTex = new Texture("DoFCoCTex").format(Format.R16F).build();
    registerShader(
      Stage.POST_RENDER,
      new Composite("DoFCoC").vertex("program/fullscreen.vsh").fragment("program/post/DoFCoC.fsh").target(0, DoFCoCTex).build()
    );
    const DoFTex = new Texture("DoFTex").format(Format.RGB16F).width(screenWidth * 0.5).height(screenWidth * 0.5).build();
    registerShader(
      Stage.POST_RENDER,
      new Composite("DoFBlur").vertex("program/fullscreen.vsh").fragment("program/post/DoFBlur.fsh").target(0, DoFTex).build()
    );
    registerShader(
      Stage.POST_RENDER,
      new Composite("DoFBlend").vertex("program/fullscreen.vsh").fragment("program/post/DoFBlend.fsh").target(0, sceneTex.target).build()
    );
  }
  registerShader(
    Stage.POST_RENDER,
    new Composite("temporalFilter").vertex("program/fullscreen.vsh").fragment("program/post/temporalFilter.fsh").target(0, sceneTex.target).build()
  );
  registerShader(
    Stage.POST_RENDER,
    new Composite("copyHistory").vertex("program/fullscreen.vsh").fragment("program/post/copyHistory.fsh").target(0, previousSceneTex).target(1, previousDepthTex).build()
  );
  if (getBoolSetting("BLOOM_ENABLE")) {
    const bloomTex = new Texture("bloomTex").format(Format.RGB16F).clear(true).mipmap(true).build();
    for (let i = 0; i < 5; i++) {
      registerShader(
        Stage.POST_RENDER,
        new Composite(`bloomDownsample${i}-${i + 1}`).vertex("program/fullscreen.vsh").fragment("program/post/bloomDownsample.fsh").target(0, bloomTex, i + 1).define("BLOOM_INDEX", i.toString()).build()
      );
    }
    for (let i = 5; i > 0; i -= 1) {
      registerShader(
        Stage.POST_RENDER,
        new Composite(`bloomUpsample${i}-${i - 1}`).vertex("program/fullscreen.vsh").fragment("program/post/bloomUpsample.fsh").target(0, bloomTex, i - 1).define("BLOOM_INDEX", i.toString()).build()
      );
    }
  }
  setCombinationPass(
    new CombinationPass("program/final.fsh").define(sceneTex.name, sceneTex.sampler).build()
  );
}
export {
  setupShader
};
//# sourceMappingURL=pack.js.map
