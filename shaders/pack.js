// pack.ts
function setLightColors() {
  setLightColor("campfire", 243, 152, 73, 255);
  setLightColor("candle", 245, 127, 68, 255);
  setLightColor("cave_vines", 243, 133, 59, 255);
  setLightColor("cave_vines_plant", 243, 133, 59, 255);
  setLightColor("glow_lichen", 107, 238, 172, 255);
  setLightColor("lantern", 243, 158, 73, 255);
  setLightColor("lava", 193, 100, 38, 255);
  setLightColor("ochre_froglight", 223, 172, 71, 255);
  setLightColor("pearlescent_froglight", 224, 117, 232, 255);
  setLightColor("redstone_torch", 249, 50, 28, 255);
  setLightColor("soul_campfire", 40, 170, 235, 255);
  setLightColor("soul_torch", 40, 170, 235, 255);
  setLightColor("torch", 243, 181, 73, 255);
  setLightColor("verdant_froglight", 99, 229, 60, 255);
  setLightColor("wall_torch", 243, 158, 73, 255);
  setLightColor("nether_portal", 200, 0, 255, 255);
  setLightColor("tinted_glass", 50, 38, 56, 255);
  setLightColor("white_stained_glass", 255, 255, 255, 255);
  setLightColor("white_stained_glass_pane", 255, 255, 255, 255);
  setLightColor("light_gray_stained_glass", 153, 153, 153, 255);
  setLightColor("light_gray_stained_glass_pane", 153, 153, 153, 255);
  setLightColor("gray_stained_glass", 76, 76, 76, 255);
  setLightColor("gray_stained_glass_pane", 76, 76, 76, 255);
  setLightColor("black_stained_glass", 25, 25, 25, 255);
  setLightColor("black_stained_glass_pane", 25, 25, 25, 255);
  setLightColor("brown_stained_glass", 102, 76, 51, 255);
  setLightColor("brown_stained_glass_pane", 102, 76, 51, 255);
  setLightColor("red_stained_glass", 153, 51, 51, 255);
  setLightColor("red_stained_glass_pane", 153, 51, 51, 255);
  setLightColor("orange_stained_glass", 216, 127, 51, 255);
  setLightColor("orange_stained_glass_pane", 216, 127, 51, 255);
  setLightColor("yellow_stained_glass", 229, 229, 51, 255);
  setLightColor("yellow_stained_glass_pane", 229, 229, 51, 255);
  setLightColor("lime_stained_glass", 127, 204, 25, 255);
  setLightColor("lime_stained_glass_pane", 127, 204, 25, 255);
  setLightColor("green_stained_glass", 102, 127, 51, 255);
  setLightColor("green_stained_glass_pane", 102, 127, 51, 255);
  setLightColor("cyan_stained_glass", 76, 127, 153, 255);
  setLightColor("cyan_stained_glass_pane", 76, 127, 153, 255);
  setLightColor("light_blue_stained_glass", 102, 153, 216, 255);
  setLightColor("light_blue_stained_glass_pane", 102, 153, 216, 255);
  setLightColor("blue_stained_glass", 51, 76, 178, 255);
  setLightColor("blue_stained_glass_pane", 51, 76, 178, 255);
  setLightColor("purple_stained_glass", 127, 63, 178, 255);
  setLightColor("purple_stained_glass_pane", 127, 63, 178, 255);
  setLightColor("magenta_stained_glass", 178, 76, 216, 255);
  setLightColor("magenta_stained_glass_pane", 178, 76, 216, 255);
  setLightColor("pink_stained_glass", 242, 127, 165, 255);
  setLightColor("pink_stained_glass_pane", 242, 127, 165, 255);
}
function defineBoolGlobally(define) {
  if (getBoolSetting(define)) {
    defineGlobally(define, 1);
  }
}
function setupShader() {
  defineBoolGlobally("BLOOM_ENABLE");
  defineGlobally("SHADOW_SAMPLES", getIntSetting("SHADOW_SAMPLES"));
  defineBoolGlobally("DEBUG_ENABLE");
  setLightColors();
  const maxMip = Math.floor(Math.log2(Math.max(screenWidth, screenHeight)));
  worldSettings.ambientOcclusionLevel = 1;
  worldSettings.disableShade = true;
  worldSettings.renderEntityShadow = false;
  worldSettings.shadowMapResolution = 1024;
  worldSettings.sunPathRotation = -40;
  worldSettings.renderSun = false;
  const sceneData = new Buffer(32).clear(true).build();
  const blueNoiseTex = new PNGTexture("blueNoiseTex", "textures/blueNoise.png", false, true);
  const debugTex = new Texture("debugTex").format(Format.RGBA8).imageName("debugImg").width(screenWidth).height(screenHeight).clear(true).clearColor(0, 0, 0, 0).build();
  const previousSceneTex = new Texture("previousSceneTex").format(Format.RGB16F).clear(false).mipmap(true).build();
  const previousDepthTex = new Texture("previousDepthTex").format(Format.RG16).clear(false).mipmap(true).build();
  ;
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
  const skyViewLUT = new Texture("skyViewLUTTex").format(Format.RGBA16F).imageName("skyViewLUT").width(200).height(200).clear(true).build();
  registerShader(
    Stage.PRE_RENDER,
    new Compute("generateSkyViewLUT").location("program/sky/generateSkyViewLUT.csh").workGroups(25, 25, 1).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.PRE_RENDER,
    new Compute("getSkylightColor").location("program/sky/getSkylightColor.csh").workGroups(1, 1, 1).ssbo(0, sceneData).build()
  );
  registerShader(Stage.PRE_RENDER, new MemoryBarrier(SSBO_BIT));
  registerShader(
    Stage.PRE_RENDER,
    new GenerateMips(previousSceneTex)
  );
  const shadowColorTex = new ArrayTexture("shadowColorTex").format(Format.RGBA8).clear(true).build();
  const shadowNormalTex = new ArrayTexture("shadowNormalTex").format(Format.RGBA8).clear(true).clearColor(0, 0, 0, 0).build();
  const shadowPositionTex = new ArrayTexture("shadowPositionTex").format(Format.RGB16F).clear(true).build();
  registerShader(
    new ObjectShader("shadow", Usage.SHADOW).vertex("program/gbuffer/shadow.vsh").fragment("program/gbuffer/shadow.fsh").target(0, shadowColorTex).target(1, shadowNormalTex).target(2, shadowPositionTex).build()
  );
  const sceneTex = new Texture("sceneTex").format(Format.RGB16F).clear(true).clearColor(0, 0, 0, 1).build();
  const translucentsTex = new Texture("translucentsTex").format(Format.RGBA16F).clear(true).clearColor(0, 0, 0, 0).build();
  const gbufferDataTex1 = new Texture("gbufferDataTex1").format(Format.RGBA16).clear(true).build();
  const gbufferDataTex2 = new Texture("gbufferDataTex2").format(Format.RGBA16).clear(true).build();
  registerShader(
    new ObjectShader("sky", Usage.SKYBOX).vertex("program/gbuffer/sky.vsh").fragment("program/gbuffer/sky.fsh").define("SKY_BASIC", "1").target(0, sceneTex).build()
  );
  registerShader(
    new ObjectShader("sky", Usage.SKY_TEXTURES).vertex("program/gbuffer/sky.vsh").fragment("program/gbuffer/sky.fsh").define("SKY_TEXTURED", "2").target(0, sceneTex).build()
  );
  const deferredGbuffers = [
    Usage.TERRAIN_SOLID,
    Usage.TERRAIN_CUTOUT,
    Usage.ENTITY_SOLID,
    Usage.ENTITY_CUTOUT,
    Usage.BLOCK_ENTITY,
    Usage.PARTICLES
  ];
  const forwardGbuffers = [
    Usage.TERRAIN_TRANSLUCENT,
    Usage.ENTITY_TRANSLUCENT,
    Usage.BLOCK_ENTITY_TRANSLUCENT,
    Usage.PARTICLES_TRANSLUCENT,
    Usage.HAND
  ];
  deferredGbuffers.forEach((program) => {
    registerShader(
      new ObjectShader("terrain", program).vertex("program/gbuffer/main.vsh").fragment("program/gbuffer/main.fsh").target(0, sceneTex).target(1, gbufferDataTex1).target(2, gbufferDataTex2).ssbo(0, sceneData).build()
    );
  });
  forwardGbuffers.forEach((program) => {
    registerShader(
      new ObjectShader("terrain", program).vertex("program/gbuffer/main.vsh").fragment("program/gbuffer/main.fsh").target(0, translucentsTex).target(1, gbufferDataTex1).target(2, gbufferDataTex2).define("FORWARD_LIGHTING", "1").ssbo(0, sceneData).build()
    );
  });
  registerShader(
    new ObjectShader("clouds", Usage.CLOUDS).vertex("program/gbuffer/discard.vsh").fragment("program/gbuffer/discard.fsh").build()
  );
  registerShader(Stage.PRE_TRANSLUCENT, new MemoryBarrier(IMAGE_BIT));
  const voxelMapWidth = 256;
  const voxelMapHeight = 128;
  defineGlobally("VOXEL_MAP_SIZE", `vec3(${voxelMapWidth}, ${voxelMapHeight}, ${voxelMapWidth})`);
  const floodfillVoxelMap1 = new Texture("floodFillVoxelMapTex1").format(Format.R11F_G11F_B10F).imageName("floodFillVoxelMap1").clear(false).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  const floodfillVoxelMap2 = new Texture("floodFillVoxelMapTex2").format(Format.R11F_G11F_B10F).imageName("floodFillVoxelMap2").clear(false).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  const voxelMap = new Texture("voxelMapTex").format(Format.RGBA8).imageName("voxelMap").clear(true).clearColor(0, 0, 0, 0).width(voxelMapWidth).height(voxelMapHeight).depth(voxelMapWidth).build();
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Compute("floodfillPropagate").location("program/composite/floodfillPropagate.csh").workGroups(voxelMapWidth / 4, voxelMapHeight / 4, voxelMapWidth / 4).build()
  );
  registerShader(Stage.PRE_TRANSLUCENT, new MemoryBarrier(IMAGE_BIT));
  const globalIlluminationTex = new Texture("globalIlluminationTex").format(Format.R11F_G11F_B10F).clear(false).width(Math.floor(screenWidth / 4)).height(Math.floor(screenHeight / 4)).build();
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("globalIllumination").vertex("program/fullscreen.vsh").fragment("program/composite/globalIllumination.fsh").target(0, globalIlluminationTex).build()
  );
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("compositeSky").vertex("program/fullscreen.vsh").fragment("program/composite/compositeSky.fsh").target(0, sceneTex).build()
  );
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("deferredShading").vertex("program/fullscreen.vsh").fragment("program/composite/deferredShading.fsh").target(0, sceneTex).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.POST_RENDER,
    new Composite("compositeTranslucents").vertex("program/fullscreen.vsh").fragment("program/composite/compositeTranslucents.fsh").target(0, sceneTex).ssbo(0, sceneData).build()
  );
  registerShader(
    Stage.POST_RENDER,
    new Composite("temporalFilter").vertex("program/fullscreen.vsh").fragment("program/post/temporalFilter.fsh").target(0, sceneTex).build()
  );
  registerShader(
    Stage.POST_RENDER,
    new Composite("copyHistory").vertex("program/fullscreen.vsh").fragment("program/post/copyHistory.fsh").target(0, previousSceneTex).target(1, previousDepthTex).build()
  );
  if (getBoolSetting("BLOOM_ENABLE")) {
    const bloomTex = new Texture("bloomTex").format(Format.RGB16F).clear(true).mipmap(true).build();
    for (let i = 0; i < 8; i++) {
      registerShader(
        Stage.POST_RENDER,
        new Composite(`bloomDownsample${i}-${i + 1}`).vertex("program/fullscreen.vsh").fragment("program/post/bloomDownsample.fsh").target(0, bloomTex, i + 1).define("BLOOM_INDEX", i.toString()).build()
      );
    }
    for (let i = 8; i > 0; i -= 1) {
      registerShader(
        Stage.POST_RENDER,
        new Composite(`bloomUpsample${i}-${i - 1}`).vertex("program/fullscreen.vsh").fragment("program/post/bloomUpsample.fsh").target(0, bloomTex, i - 1).define("BLOOM_INDEX", i.toString()).build()
      );
    }
  }
  setCombinationPass(
    new CombinationPass("program/final.fsh").build()
  );
}
export {
  setupShader
};
//# sourceMappingURL=pack.js.map
