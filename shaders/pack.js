// pack.ts
function setupShader(dimension) {
  worldSettings.disableShade = true;
  worldSettings.sunPathRotation = 40;
  worldSettings.shadow.resolution = 1592;
  worldSettings.shadow.far = 120;
  worldSettings.shadow.distance = 120;
  worldSettings.shadow.enable();
  worldSettings.mergedHandDepth = true;
  const sceneData = new GPUBuffer(16).clear(true).build();
  const sunTransmittanceLUT = new Texture("sun_transmittance_lut_tex").format(Format.RGBA16F).imageName("sun_transmittance_lut").width(256).height(64).clear(false).build();
  const multipleScatteringLUT = new Texture("multiple_scattering_lut_tex").format(Format.RGBA16F).imageName("multiple_scattering_lut").width(32).height(32).clear(false).build();
  const skyViewLUT = new Texture("sky_view_lut_tex").format(Format.RGBA16F).imageName("sky_view_lut").width(200).height(200).clear(true).mipmap(true).build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)");
  registerShader(
    Stage.SCREEN_SETUP,
    new Compute("generateSunTransmittanceLUT").location("program/atmosphere/generate_sun_transmittance_lut.csh").workGroups(32, 8, 1).build()
  );
  registerShader(
    Stage.SCREEN_SETUP,
    new Compute("generateMultipleScatteringLUT").location("program/atmosphere/generate_multiple_scattering_lut.csh").workGroups(4, 4, 1).build()
  );
  registerShader(
    Stage.PRE_RENDER,
    new Compute("generateSkyViewLUT").location("program/atmosphere/generate_sky_view_lut.csh").workGroups(25, 25, 1).ssbo(0, sceneData).build()
  );
  const skyIrradianceLUT = new Texture("sky_irradiance_lut_tex").format(Format.RGBA16F).imageName("sky_irradiance_lut").width(32).height(32).clear(true).mipmap(true).build();
  registerShader(
    Stage.PRE_RENDER,
    new Compute("generateSkyIrradianceLUT").location("program/render_setup/generate_sky_irradiance_lut.csh").workGroups(4, 4, 1).ssbo(0, sceneData).build()
  );
  registerShader(
    new ObjectShader("shadow", Usage.SHADOW).vertex("program/geometry/shadow.vsh").fragment("program/geometry/shadow.fsh").build()
  );
  const gbufferTex1 = new Texture("gbuffer_tex_1").format(Format.RGBA16).clear(true).build();
  const gbufferTex2 = new Texture("gbuffer_tex_2").format(Format.RGBA16).clear(true).build();
  registerShader(
    new ObjectShader("terrain", Usage.TEXTURED).vertex("program/geometry/opaque.vsh").fragment("program/geometry/opaque.fsh").target(0, gbufferTex1).target(1, gbufferTex2).build()
  );
  const finalColorTex = new Texture("final_color_tex").format(Format.RGBA32F).clear(true).build();
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("sky").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/render_sky.fsh").target(0, finalColorTex).build()
  );
  registerShader(
    Stage.PRE_TRANSLUCENT,
    new Composite("opaqueDiffuse").vertex("program/fullscreen_pass.vsh").fragment("program/before_translucents/combine_diffuse.fsh").target(0, finalColorTex).ssbo(0, sceneData).build()
  );
  setCombinationPass(new CombinationPass("program/combination.fsh").build());
}
export {
  setupShader
};
//# sourceMappingURL=pack.js.map
