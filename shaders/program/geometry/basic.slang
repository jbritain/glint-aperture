import aperture;

struct VertexOutput {
    // The value after the colon is known as a "semantic", and denotes a special value used by the graphics pipeline.
    // There are many of these usable in both vertex and fragment, but in this case, SV_Position is all we care about;
    // it is equivalent to writing gl_Position.
    float4 position : SV_Position;
    float2 uv;
    float4 color;
    float2 light;
    float distance;
};

[[shader("vertex")]]
VertexOutput vertexMain(Vertex input) {
    VertexOutput output;

    float4 modelPos = input.pos();

    output.position = mul(input.projectionMatrix(), mul(input.viewMatrix(), modelPos));
    output.uv = input.uv();
    output.color = input.color();
    output.light = input.light();
    output.distance = length(modelPos);

    if (let overlayColor = input.overlayColor()) {
        output.color = lerp(output.color, overlayColor, overlayColor.a);
    }

    return output;
}

[[shader("fragment")]]
float4 fragmentMain(VertexOutput input) : SV_Target0 {
    float4 color = albedoTex.Sample(input.uv) * input.color;

    iris_discardIfNeeded(color);

    return color;
}
