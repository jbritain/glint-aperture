export function configureRenderer(renderer: RendererConfig): void {
    renderer.mergedHandDepth = true;
    renderer.ambientOcclusionLevel = 1.0;
    renderer.disableShade = true;
    renderer.render.entityShadow = false;
}


export function configurePipeline(pipeline: PipelineConfig): void {
    let sceneTex = pipeline.createTexture("sceneTex")
            .width(screenWidth)
            .height(screenHeight)
            .format(Format.RGBA8)
            .build();

    pipeline.createObjectShader("basic", Usage.BASIC)
            .location("program/geometry/basic")
            .target(0, sceneTex)
            .compile();


    // The combination pass. For more information, see the file.
    pipeline.createCombinationPass("program/combination").compile();
}

export function beginFrame(state : WorldState) : void {
    // This runs every frame. However, it won't be used in this template.
}