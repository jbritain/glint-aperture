import aperture;

Sampler2D sceneTex;

[[shader("fragment")]]
float4 main(float2 pos: SV_Position) : SV_Target0 {
    return sceneTex[int2(pos)];
}
