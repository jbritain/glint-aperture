function setupShader() {    
    worldSettings.ambientOcclusionLevel = 1.0;
    worldSettings.disableShade = true;
    worldSettings.renderEntityShadow = false;
    worldSettings.shadowMapResolution = 2048;

    let sceneTex = new Texture("sceneTex").format(Format.RGB16F)
    .clear(true).build();

    let shadowColorTex = new ArrayTexture("shadowColorTex").format(Format.RGBA8)
    .clear(true).build();

    registerShader(
        new ObjectShader("terrain", Usage.BASIC)
        .vertex("program/gbuffer/main.vsh")
        .fragment("program/gbuffer/main.fsh")
        .target(0, sceneTex)
        .build()
    );

    registerShader(
        new ObjectShader("shadow", Usage.SHADOW)
        .vertex("program/gbuffer/shadow.vsh")
        .fragment("program/gbuffer/shadow.fsh")
        .target(0, shadowColorTex)
        .build()
    )

    registerUniforms(
        // "atlasSize",
        "cameraPos",
        "cascadeSize",
        // "cloudHeight",
        // "dayProgression",
        "eyeBrightness",
        "farPlane",
        "fogColor",
        "fogStart",
        "fogEnd",
        "frameTime",
        "frameCounter",
        "guiHidden",
        "isEyeInWater",
        "lastCameraPos",
        "lastPlayerProjection",
        "lastPlayerModelView",
        "nearPlane",
        "playerModelView",
        "playerModelViewInverse",
        "playerProjection",
        "playerProjectionInverse",
        "rainStrength",
        "renderDistance",
        "screenSize",
        "shadowLightPosition",
        "shadowModelView",
        // "shadowModelViewInverse",
        "shadowProjection",
        "shadowProjectionSize",
        "skyColor",
        "sunPosition",
        "timeCounter",
        "worldTime");

    finalizeUniforms();


    setCombinationPass(new CombinationPass("program/final.fsh").build())
}
