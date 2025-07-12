#include <metal_stdlib>
using namespace metal;

struct CircleVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex CircleVertexOut circle_vertices(uint vertex_id [[vertex_id]],
                           constant float2 *vertices [[buffer(1)]]) {
    
    float2 pos = vertices[vertex_id];
    
    CircleVertexOut out;
    out.position = float4(pos.x, pos.y, 0.0, 1.0);
    out.uv = pos;
    
    return out;
}

fragment float4 circle_fragments(CircleVertexOut in [[stage_in]],
                                constant float &radius [[buffer(0)]],
                                constant float2 &center [[buffer(1)]]) {
    float2 offset = in.uv - center;
    float dist = length(offset);
    
    if (dist > radius) {
        // return float4(1, 1, 1, 0.5); // debug. transparent white
        return float4(0, 0, 0, 0);
    }
    
    return float4(1, 1, 1, 1);
}
