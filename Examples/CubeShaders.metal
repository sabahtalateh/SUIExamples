#include <metal_stdlib>
using namespace metal;

// Vertex input structure
struct CubeVertex {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

// Uniforms structure
struct CubeUniforms {
    float4x4 mvpMatrix;
};

// Vertex output structure
struct CubeVertexOut {
    float4 position [[position]];
    float4 color;
    float3 worldPosition;
};

// Vertex shader
vertex CubeVertexOut metalkit_cube_vertex(CubeVertex in [[stage_in]],
                                         constant CubeUniforms &uniforms [[buffer(1)]]) {
    CubeVertexOut out;
    
    // Transform vertex position
    out.position = uniforms.mvpMatrix * float4(in.position, 1.0);
    
    // Pass through color
    out.color = in.color;
    
    // Pass world position for potential lighting
    out.worldPosition = in.position;
    
    return out;
}

// Fragment shader
fragment float4 metalkit_cube_fragment(CubeVertexOut in [[stage_in]]) {
    // Simple lighting based on position
    float3 lightDirection = normalize(float3(1.0, 1.0, 1.0));
    float3 normal = normalize(cross(dfdx(in.worldPosition), dfdy(in.worldPosition)));
    
    // Calculate light intensity
    float lightIntensity = max(0.9, dot(normal, lightDirection));
    
    // Apply lighting to color
    float3 litColor = in.color.rgb * lightIntensity;
    
    return float4(litColor, in.color.a);
}
