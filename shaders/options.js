// options.ts
function setupOptions() {
  const postPage = new Page("Post-Processing").add(asBool("BLOOM_ENABLE", true)).build();
  const lightingPage = new Page("Shadows & Lighting").add(asIntRange("SHADOW_SAMPLES", 8, 4, 32, 1)).build();
  return new Page("Glint").add(postPage).add(lightingPage).add(asBool("DEBUG_ENABLE", false)).build();
}
function asIntRange(key, defaultVal, minVal, maxVal, interval) {
  let vals = getRange(minVal, maxVal, interval);
  return asInt(key, ...vals).build(defaultVal);
}
function getRange(minVal, maxVal, interval) {
  let vals = [];
  for (let val = minVal; val <= maxVal; val++) {
    vals.push(val);
  }
  return vals;
}
export {
  setupOptions
};
//# sourceMappingURL=options.js.map
