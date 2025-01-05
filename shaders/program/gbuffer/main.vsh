#version 450 core

void iris_emitVertex(inout VertexData data) {
    // It's that simple.
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}


out vec2 uv;
out vec2 light;
out vec4 vertColor;
out vec3 viewPos;
out mat3 tbnMatrix;

void iris_sendParameters(VertexData data) {
    // AO is separated by default. Add it here.
    vec3 colRGB = data.color.rgb * data.ao;
    vertColor = vec4(mix(data.overlayColor.rgb, colRGB, data.overlayColor.a), data.color.a); // This applies the red hit flash, if applicable.

    uv = data.uv;
    light = data.light;

    viewPos = (playerProjectionInverse * data.clipPos).xyz;

    tbnMatrix[2] = normalize(mat3(iris_modelViewMatrix) * data.normal.xyz);
    tbnMatrix[0] = normalize(mat3(iris_modelViewMatrix) * data.tangent.xyz);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * data.tangent.w);
}