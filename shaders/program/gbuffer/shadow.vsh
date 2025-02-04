#version 450 core
#extension GL_ARB_shader_viewport_layer_array : require

void iris_emitVertex(inout VertexData data) {
    data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

out vec2 uv;
out vec4 color;
out vec3 normal;
out vec3 playerPos;
flat out uint blockID;

void iris_sendParameters(VertexData data) {
    color = data.color;
    uv = data.uv;
    normal = normalize(mat3(inverse(ap.celestial.view)) * mat3(iris_modelViewMatrix) * data.normal.xyz); // TODO: change this when IMS adds shadow model view inverse
    playerPos = ((inverse(ap.celestial.view) * inverse(iris_projectionMatrix) * data.clipPos)).xyz;
    blockID = data.blockId;
}