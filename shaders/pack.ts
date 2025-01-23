function setupShader() {    
    worldSettings.ambientOcclusionLevel = 1.0;
    worldSettings.disableShade = true;
    worldSettings.renderEntityShadow = false;
    worldSettings.shadowMapResolution = 1024;
    worldSettings.sunPathRotation = -40.0;

    const sceneData = new Buffer(32)
        .clear(true)
        .build();

    let sunTransmittanceLUT = new Texture("sunTransmittanceLUTTex")
        .format(Format.RGBA16F)
        .imageName("sunTransmittanceLUT")
        .width(256).height(64)
        .clear(false)
        .build();

    registerShader(
        Stage.SCREEN_SETUP,
        new Compute("generateSunTransmittanceLUT")
        .location("program/sky/generateSunTransmittanceLUT.csh")
        .workGroups(32, 8, 1)
        .build()
    )

    let multipleScatteringLUT = new Texture("multipleScatteringLUTTex")
        .format(Format.RGBA16F)
        .imageName("multipleScatteringLUT")
        .width(32).height(32)
        .clear(false)
        .build();

    registerShader(
        Stage.SCREEN_SETUP,
        new Compute("generateMultipleScatteringLUT")
        .location("program/sky/generateMultipleScatteringLUT.csh")
        .workGroups(4, 4, 1)
        .build()
    )

    let skyViewLUT = new Texture("skyViewLUTTex")
        .format(Format.RGBA16F)
        .imageName("skyViewLUT")
        .width(200).height(200)
        // .mipmap(true)
        .clear(true)
        .build()

    registerShader(
        Stage.PRE_RENDER,
        new Compute("generateSkyViewLUT")
        .location("program/sky/generateSkyViewLUT.csh")
        .workGroups(25, 25, 1)
        .ssbo(0, sceneData)
        .build()
    )

    registerShader(
        Stage.PRE_RENDER,
        new Compute("getSkylightColor")
        .location("program/sky/getSkylightColor.csh")
        .workGroups(1, 1, 1)
        .ssbo(0, sceneData)
        .build()
    )

    let sceneTex = new Texture("sceneTex")
        .format(Format.RGB16F)
        .clear(true)
        .build();

    let shadowColorTex = new ArrayTexture("shadowColorTex")
        .format(Format.RGBA8)
        .clear(true)
        .build();

    registerShader(
        new ObjectShader("terrain", Usage.TERRAIN_SOLID)
        .vertex("program/gbuffer/main.vsh")
        .fragment("program/gbuffer/main.fsh")
        .target(0, sceneTex)
        .ssbo(0, sceneData)
        .build()
    );

    registerShader(
        new ObjectShader("shadow", Usage.SHADOW)
        .vertex("program/gbuffer/shadow.vsh")
        .fragment("program/gbuffer/shadow.fsh")
        .target(0, shadowColorTex)
        .build()
    );

    registerShader(
        Stage.PRE_TRANSLUCENT,
        new Composite("compositeSky")
        .vertex("program/fullscreen.vsh")
        .fragment("program/composite/compositeSky.fsh")
        .target(0, sceneTex)
        .build()
    );


    setCombinationPass(new CombinationPass("program/final.fsh").build());
}
