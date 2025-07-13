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
  const sceneData = new GPUBuffer(16).clear(true).build();
  const debugTex = new Texture("debug_tex").format(Format.RGBA8).imageName("debug").clear(true).build();
  const sunTransmittanceLUT = new Texture("sun_transmittance_lut_tex").format(Format.RGBA16F).imageName("sun_transmittance_lut").width(256).height(64).clear(false).build();
  const multipleScatteringLUT = new Texture("multiple_scattering_lut_tex").format(Format.RGBA16F).imageName("multiple_scattering_lut").width(32).height(32).clear(false).build();
  const skyViewLUT = new Texture("sky_view_lut_tex").format(Format.RGBA16F).imageName("sky_view_lut").width(200).height(200).clear(true).mipmap(true).build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)");
  pipeline.registerPostPass(
    Stage.SCREEN_SETUP,
    new Compute("generateSunTransmittanceLUT").location("program/atmosphere/generate_sun_transmittance_lut.csh").workGroups(32, 8, 1).build()
  );
  pipeline.addBarrier(Stage.SCREEN_SETUP, IMAGE_BIT);
  pipeline.registerPostPass(
    Stage.SCREEN_SETUP,
    new Compute("generateMultipleScatteringLUT").location("program/atmosphere/generate_multiple_scattering_lut.csh").workGroups(4, 4, 1).build()
  );
  pipeline.addBarrier(Stage.SCREEN_SETUP, IMAGE_BIT);
  pipeline.registerPostPass(
    Stage.PRE_RENDER,
    new Compute("generateSkyViewLUT").location("program/atmosphere/generate_sky_view_lut.csh").workGroups(25, 25, 1).ssbo(0, sceneData).build()
  );
  pipeline.addBarrier(Stage.PRE_RENDER, IMAGE_BIT);
  const skyIrradianceLUT = new Texture("sky_irradiance_lut_tex").format(Format.RGBA16F).imageName("sky_irradiance_lut").width(32).height(32).clear(true).build();
  pipeline.registerPostPass(
    Stage.PRE_RENDER,
    new Compute("generateSkyIrradianceLUT").location("program/render_setup/generate_sky_irradiance_lut.csh").workGroups(4, 4, 1).ssbo(0, sceneData).build()
  );
  pipeline.addBarrier(Stage.PRE_RENDER, IMAGE_BIT);
  pipeline.registerObjectShader(
    new ObjectShader("shadow", Usage.SHADOW).vertex("program/geometry/shadow.vsh").fragment("program/geometry/shadow.fsh").build()
  );
  const gbufferTex1 = new Texture("gbuffer_tex_1").format(Format.RGBA16).clear(true).build();
  const gbufferTex2 = new Texture("gbuffer_tex_2").format(Format.RGBA16).clear(true).build();
  pipeline.registerObjectShader(
    new ObjectShader("terrain", Usage.TEXTURED).vertex("program/geometry/opaque.vsh").fragment("program/geometry/opaque.fsh").target(0, gbufferTex1).target(1, gbufferTex2).build()
  );
  const shadowTex = new Texture("shadow_tex").format(Format.RGB8).clear(true).build();
  const subsurfaceScatterTex = new Texture("subsurface_scatter_tex").format(Format.RGB8).clear(true).build();
  pipeline.registerPostPass(
    Stage.PRE_TRANSLUCENT,
    new Composite("opaque_shadowing").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/opaque_shadowing.fsh").target(0, shadowTex).target(1, subsurfaceScatterTex).build()
  );
  const finalColorTex = new Texture("final_color_tex").format(Format.RGBA32F).clear(true).build();
  pipeline.registerPostPass(
    Stage.PRE_TRANSLUCENT,
    new Composite("sky").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/render_sky.fsh").target(0, finalColorTex).build()
  );
  pipeline.registerPostPass(
    Stage.PRE_TRANSLUCENT,
    new Composite("opaqueDiffuse").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/combine_diffuse.fsh").target(0, finalColorTex).ssbo(0, sceneData).build()
  );
  pipeline.setCombinationPass(new CombinationPass("program/combination.fsh").build());
}
export {
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
