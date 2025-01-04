#version 450 core

void iris_emitVertex(inout VertexData data) {
    // It's that simple.
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}


out vec2 uv;
out vec2 light;
out vec4 vertColor;
out vec3 viewPos;
out vec3 normal;

void iris_sendParameters(VertexData data) {
    // AO is separated by default. Add it here.
    vec3 colRGB = data.color.rgb * data.ao;
    vertColor = vec4(mix(data.overlayColor.rgb, colRGB, data.overlayColor.a), data.color.a); // This applies the red hit flash, if applicable.

    uv = data.uv;
    light = data.light;

    viewPos = (playerProjectionInverse * data.clipPos).xyz;

    normal = mat3(iris_modelViewMatrix) * data.normal;
}