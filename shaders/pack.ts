function setupShader() {    
    if(getBoolSetting("BLOOM_ENABLED")){
        defineGlobally("BLOOM_ENABLED", 1);
    }

    defineGlobally("SHADOW_SAMPLES", getIntSetting("SHADOW_SAMPLES"));


    worldSettings.ambientOcclusionLevel = 1.0;
    worldSettings.disableShade = true;
    worldSettings.renderEntityShadow = false;
    worldSettings.shadowMapResolution = 1024;
    worldSettings.sunPathRotation = -40.0;

    const sceneData = new Buffer(32)
        .clear(true)
        .build();

    // ======================= SETUP =======================

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
        .clear(true)
        .build()

    // ======================= PREPARE =======================

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

    // ======================= GBUFFERS =======================

    let sceneTex = new Texture("sceneTex")
        .format(Format.RGB16F)
        .clear(true)
        .build();

    let shadowColorTex = new ArrayTexture("shadowColorTex")
        .format(Format.RGBA8)
        .clear(true)
        .build();

    registerShader(
        new ObjectShader("terrain", Usage.TEXTURED)
        .vertex("program/gbuffer/main.vsh")
        .fragment("program/gbuffer/main.fsh")
        .target(0, sceneTex)
        .ssbo(0, sceneData)
        .build()
    );

    registerShader(
        new ObjectShader("terrain", Usage.CLOUDS)
        .vertex("program/gbuffer/discard.vsh")
        .fragment("program/gbuffer/discard.fsh")
        .build()
    );

    registerShader(
        new ObjectShader("shadow", Usage.SHADOW)
        .vertex("program/gbuffer/shadow.vsh")
        .fragment("program/gbuffer/shadow.fsh")
        .target(0, shadowColorTex)
        .build()
    );

    // ======================= DEFERRED =======================

    registerShader(
        Stage.PRE_TRANSLUCENT,
        new Composite("compositeSky")
        .vertex("program/fullscreen.vsh")
        .fragment("program/composite/compositeSky.fsh")
        .target(0, sceneTex)
        .build()
    );

    // ======================= COMPOSITES =======================


    if(getBoolSetting("BLOOM_ENABLED")){
        let bloomTex = new Texture("bloomTex")
            .format(Format.RGB16F)
            .clear(true)
            .mipmap(true)
            .build();

        for(let i = 0; i < 8; i++){
            registerShader(
                Stage.POST_RENDER,
                new Composite(`bloomDownsample${i}-${i+1}`)
                .vertex("program/fullscreen.vsh")
                .fragment("program/composite/bloomDownsample.fsh")
                .target(0, bloomTex, i + 1)
                .define("BLOOM_INDEX", i.toString())
                .build()
            )
        }
    
        for(let i = 8; i > 0; i -= 1){
            registerShader(
                Stage.POST_RENDER,
                new Composite(`bloomUpsample${i}-${i-1}`)
                .vertex("program/fullscreen.vsh")
                .fragment("program/composite/bloomUpsample.fsh")
                .target(0, bloomTex, i - 1)
                .define("BLOOM_INDEX", i.toString())
                .build()
            )
        }
    }




    setCombinationPass(
        new CombinationPass("program/final.fsh")
        .build()
    );
}
