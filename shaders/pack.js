// pack.ts
function configureRenderer(renderer) {
  renderer.disableShade = true;
  renderer.sunPathRotation = 40;
  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 120;
  renderer.shadow.distance = 120;
  renderer.shadow.enabled = true;
  renderer.mergedHandDepth = true;
}
function configurePipeline(pipeline) {
  const screenSetup = pipeline.forStage(Stage.SCREEN_SETUP);
  const preRender = pipeline.forStage(Stage.PRE_RENDER);
  const preTranslucent = pipeline.forStage(Stage.PRE_TRANSLUCENT);
  const postRender = pipeline.forStage(Stage.POST_RENDER);
  const sceneData = pipeline.createBuffer(16, true);
  const blueNoiseTex = pipeline.importPNGTexture(
    "blue_noise_tex",
    "textures/blue_noise.png",
    false,
    true
  );
  const debugTex = pipeline.createImageTexture("debug_tex", "debug").format(Format.RGBA8).clear(true).build();
  const sunTransmittanceLUT = pipeline.createImageTexture("sun_transmittance_lut_tex", "sun_transmittance_lut").format(Format.RGBA16F).width(256).height(64).clear(false).build();
  const multipleScatteringLUT = pipeline.createImageTexture(
    "multiple_scattering_lut_tex",
    "multiple_scattering_lut"
  ).format(Format.RGBA16F).width(32).height(32).clear(false).build();
  const skyViewLUT = pipeline.createImageTexture("sky_view_lut_tex", "sky_view_lut").format(Format.RGBA16F).width(200).height(200).clear(true).mipmap(true).build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)");
  const skyIrradianceLUT = pipeline.createImageTexture("sky_irradiance_lut_tex", "sky_irradiance_lut").format(Format.RGBA16F).width(32).height(32).clear(true).build();
  screenSetup.createCompute("generate_sun_transmittance_lut").location("program/atmosphere/generate_sun_transmittance_lut.csh").workGroups(32, 8, 1).compile();
  screenSetup.barrier(IMAGE_BIT);
  screenSetup.createCompute("generate_multiple_scattering_lut").location("program/atmosphere/generate_multiple_scattering_lut.csh").workGroups(4, 4, 1).compile();
  preRender.barrier(IMAGE_BIT);
  preRender.createCompute("generate_sky_view_lut").location("program/atmosphere/generate_sky_view_lut.csh").workGroups(25, 25, 1).ssbo(0, sceneData).compile();
  preRender.barrier(IMAGE_BIT);
  preRender.createCompute("generateSkyIrradianceLUT").location("program/render_setup/generate_sky_irradiance_lut.csh").workGroups(4, 4, 1).ssbo(0, sceneData).compile();
  preRender.barrier(IMAGE_BIT);
  pipeline.createObjectShader("shadow", Usage.SHADOW).vertex("program/geometry/shadow.vsh").fragment("program/geometry/shadow.fsh").compile();
  const gbufferTex1 = pipeline.createTexture("gbuffer_tex_1").format(Format.RGBA16).clear(true).build();
  const gbufferTex2 = pipeline.createTexture("gbuffer_tex_2").format(Format.RGBA16).clear(true).build();
  pipeline.createObjectShader("terrain", Usage.TEXTURED).vertex("program/geometry/opaque.vsh").fragment("program/geometry/opaque.fsh").target(0, gbufferTex1).target(1, gbufferTex2).compile();
  const shadowTex = pipeline.createTexture("shadow_tex").format(Format.RGBA8).clear(true).build();
  preTranslucent.createComposite("opaque_shadowing").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_shadowing.fsh").target(0, shadowTex).compile();
  const sceneTex = pipeline.createTexture("scene_tex").format(Format.RGBA16F).clear(true).build();
  preTranslucent.createComposite("sky").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/render_sky.fsh").target(0, sceneTex).compile();
  const diffuseTex = pipeline.createTexture("diffuse_tex").format(Format.R11F_G11F_B10F).clear(false).build();
  const specularTex = pipeline.createTexture("specular_tex").format(Format.RGBA16F).clear(false).build();
  const ssrTex = pipeline.createTexture("ssr_tex").format(Format.RGBA16F).clear(false).build();
  preTranslucent.createComposite("opaque_ssr").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_ssr.fsh").target(0, ssrTex).ssbo(0, sceneData).compile();
  preTranslucent.createComposite("opaque_shading").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_shading.fsh").target(0, sceneTex).target(1, diffuseTex).ssbo(0, sceneData).compile();
  postRender.createComposite("exposure").vertex("program/fullscreen_pass.vsh").fragment("program/post/exposure.fsh").target(0, sceneTex).compile();
  const bloomTex = pipeline.createTexture("bloom_tex").format(Format.RGBA16F).clear(true).mipmap(true).build();
  for (let i = 0; i < 5; i++) {
    postRender.createComposite(`bloom_ownsample${i}-${i + 1}`).vertex("program/fullscreen_pass.vsh").fragment("program/post/bloom_downsample.fsh").target(0, bloomTex, i + 1).define("BLOOM_INDEX", i.toString()).compile();
  }
  for (let i = 5; i > 0; i -= 1) {
    postRender.createComposite(`bloomUpsample${i}-${i - 1}`).vertex("program/fullscreen_pass.vsh").fragment("program/post/bloom_upsample.fsh").target(0, bloomTex, i - 1).define("BLOOM_INDEX", i.toString()).compile();
  }
  screenSetup.end();
  preRender.end();
  preTranslucent.end();
  postRender.end();
  pipeline.createCombinationPass("program/combination.fsh").compile();
}
export {
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
