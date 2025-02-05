#version 450 core

void iris_emitVertex(inout VertexData data) {
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}


out vec2 uv;
out vec2 light;
out vec4 vertColor;
out vec3 viewPos;
out mat3 tbnMatrix;
flat out uint blockID;

out vec4 textureBounds;
out vec2 singleTexSize;

out vec3 midBlock;

void iris_sendParameters(VertexData data) {
    blockID = data.blockId;
    
    vec3 colRGB = data.color.rgb * data.ao;
    vertColor = vec4(mix(data.overlayColor.rgb, colRGB, data.overlayColor.a), data.color.a); // This applies the red hit flash, if applicable.

    uv = data.uv;
    light = data.light;

    viewPos = (ap.camera.projectionInv * data.clipPos).xyz;

    tbnMatrix[2] = normalize(mat3(iris_modelViewMatrix) * data.normal.xyz);
    tbnMatrix[0] = normalize(mat3(iris_modelViewMatrix) * data.tangent.xyz);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * data.tangent.w);

    textureBounds.xy = iris_getTexture(data.textureId).minCoord;
    textureBounds.zw = iris_getTexture(data.textureId).maxCoord;

    singleTexSize = (textureBounds.zw - textureBounds.xy);

    midBlock = data.midBlock;
}