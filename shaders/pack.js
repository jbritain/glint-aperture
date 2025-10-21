// pack.ts
function configureRenderer(renderer) {
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1;
  renderer.disableShade = true;
  renderer.render.entityShadow = false;
}
function configurePipeline(pipeline) {
  let sceneTex = pipeline.createTexture("sceneTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  pipeline.createObjectShader("basic", Usage.BASIC).location("program/geometry/basic").target(0, sceneTex).compile();
  pipeline.createCombinationPass("program/combination").compile();
}
function beginFrame(state) {
}
export {
  beginFrame,
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
