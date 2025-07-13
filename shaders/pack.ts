import type {} from "./iris";

export function configureRenderer(renderer : RendererConfig) {
  // These settings tell Aperture to render the world identically to Vanilla, except with the sun tilted.
  renderer.disableShade = true;
  renderer.sunPathRotation = 40.0;

  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 120;
  renderer.shadow.distance = 120;
  renderer.shadow.enabled = true;

  // This setting merges hand depth, as is behavior in Vanilla/Optifine. Without this, the hand's depth will be stored in a separate 'handDepth' texture.
  renderer.mergedHandDepth = true;
}

export function configurePipeline(pipeline: PipelineConfig) {
  const sceneData = new GPUBuffer(16).clear(true).build();

  const debugTex = new Texture("debug_tex")
    .format(Format.RGBA8)
    .imageName("debug")
    .clear(true)
    .build();

  const sunTransmittanceLUT = new Texture("sun_transmittance_lut_tex")
    .format(Format.RGBA16F)
    .imageName("sun_transmittance_lut")
    .width(256)
    .height(64)
    .clear(false)
    .build();
  // defineGlobally("SUN_TRANSMITTANCE_RES", `ivec2(${sunTransmittanceLUT.width}, ${sunTransmittanceLUT.height})`);

  const multipleScatteringLUT = new Texture("multiple_scattering_lut_tex")
    .format(Format.RGBA16F)
    .imageName("multiple_scattering_lut")
    .width(32)
    .height(32)
    .clear(false)
    .build();
  // defineGlobally("MULTIPLE_SCATTERING_RES", `ivec2(${multipleScatteringLUT.width}, ${multipleScatteringLUT.height})`);

  const skyViewLUT = new Texture("sky_view_lut_tex")
    .format(Format.RGBA16F)
    .imageName("sky_view_lut")
    .width(200)
    .height(200)
    .clear(true)
    .mipmap(true)
    .build();
  defineGlobally("SKY_VIEW_RES", "ivec2(200, 200)");// + multipleScatteringLUT.width.toString() + "," + multipleScatteringLUT.height.toString() + ")");

  pipeline.registerPostPass(
    Stage.SCREEN_SETUP,
    new Compute("generateSunTransmittanceLUT")
      .location("program/atmosphere/generate_sun_transmittance_lut.csh")
      .workGroups(32, 8, 1)
      .build(),
  );

  pipeline.addBarrier(Stage.SCREEN_SETUP, IMAGE_BIT);

  pipeline.registerPostPass(
    Stage.SCREEN_SETUP,
    new Compute("generateMultipleScatteringLUT")
      .location("program/atmosphere/generate_multiple_scattering_lut.csh")
      .workGroups(4, 4, 1)
      .build(),
  );

  pipeline.addBarrier(Stage.SCREEN_SETUP, IMAGE_BIT);
  
  pipeline.registerPostPass(
    Stage.PRE_RENDER,
    new Compute("generateSkyViewLUT")
      .location("program/atmosphere/generate_sky_view_lut.csh")
      .workGroups(25, 25, 1)
      .ssbo(0, sceneData)
      .build(),
  );

  pipeline.addBarrier(Stage.PRE_RENDER, IMAGE_BIT);

  const skyIrradianceLUT = new Texture("sky_irradiance_lut_tex")
    .format(Format.RGBA16F)
    .imageName("sky_irradiance_lut")
    .width(32)
    .height(32)
    .clear(true)
    .build();

  pipeline.registerPostPass(
    Stage.PRE_RENDER,
    new Compute("generateSkyIrradianceLUT")
      .location("program/render_setup/generate_sky_irradiance_lut.csh")
      .workGroups(4, 4, 1)
      .ssbo(0, sceneData)
      .build(),
  );

  pipeline.addBarrier(Stage.PRE_RENDER, IMAGE_BIT);

  // GEOMETRY
  // =======================================================================================
  pipeline.registerObjectShader(
    new ObjectShader("shadow", Usage.SHADOW)
      .vertex("program/geometry/shadow.vsh")
      .fragment("program/geometry/shadow.fsh")
      .build(),
  );

  const gbufferTex1 = new Texture("gbuffer_tex_1")
    .format(Format.RGBA16)
    .clear(true)
    .build();

  const gbufferTex2 = new Texture("gbuffer_tex_2")
    .format(Format.RGBA16)
    .clear(true)
    .build();

  pipeline.registerObjectShader(
    new ObjectShader("terrain", Usage.TEXTURED)
      .vertex("program/geometry/opaque.vsh")
      .fragment("program/geometry/opaque.fsh")
      .target(0, gbufferTex1)
      .target(1, gbufferTex2)
      .build(),
  );

  // BEFORE TRANSLUCENTS
  // =======================================================================================
  const shadowTex = new Texture("shadow_tex")
    .format(Format.RGB8)
    .clear(true)
    .build();
  
  const subsurfaceScatterTex = new Texture("subsurface_scatter_tex")
    .format(Format.RGB8)
    .clear(true)
    .build();

  pipeline.registerPostPass(Stage.PRE_TRANSLUCENT,
    new Composite("opaque_shadowing")
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/before_translucents/opaque_shadowing.fsh")
      .target(0, shadowTex)
      .target(1, subsurfaceScatterTex)
      .build()
  );
  
  const sceneTex = new Texture("scene_tex")
    .format(Format.RGBA32F)
    .clear(true)
    .build();

  pipeline.registerPostPass(
    Stage.PRE_TRANSLUCENT,
    new Composite("sky")
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/before_translucents/render_sky.fsh")
      .target(0, sceneTex)
      .build()
  );

  pipeline.registerPostPass(
    Stage.PRE_TRANSLUCENT,
    new Composite("opaqueDiffuse")
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/before_translucents/opaque_diffuse.fsh")
      .target(0, sceneTex)
      .ssbo(0, sceneData)
      .build()
  );

  //   pipeline.registerPostPass(
  //   Stage.PRE_TRANSLUCENT,
  //   new Composite("opaqueSpecular")
  //     .vertex("program/fullscreen_pass.vsh")
  //     .fragment("program/before_translucents/opaque_specular.fsh")
  //     .target(0, sceneTex)
  //     .ssbo(0, sceneData)
  //     .build()
  // );



  pipeline.registerPostPass(
    Stage.POST_RENDER,
    new Composite("exposure")
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/exposure.fsh")
      .target(0, sceneTex)
      .build()
  );

  const bloomTex = new Texture("bloom_tex")
    .format(Format.RGBA16F)
    .clear(true)
    .mipmap(true)
    .build()

  for(let i = 0; i < 5; i++){
    pipeline.registerPostPass(
      Stage.POST_RENDER,
      new Composite(`bloomDownsample${i}-${i+1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_downsample.fsh")
      .target(0, bloomTex, i + 1)
      .define("BLOOM_INDEX", i.toString())
      .build()
    )
  }
    
  for(let i = 5; i > 0; i -= 1){
    pipeline.registerPostPass(
      Stage.POST_RENDER,
      new Composite(`bloomUpsample${i}-${i-1}`)
      .vertex("program/fullscreen_pass.vsh")
      .fragment("program/post/bloom_upsample.fsh")
      .target(0, bloomTex, i - 1)
      .define("BLOOM_INDEX", i.toString())
      .build()
    )
  }

  pipeline.setCombinationPass(new CombinationPass("program/combination.fsh").build());
}
