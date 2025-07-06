#include <metal_stdlib>
using namespace metal;

struct SphereVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
};

struct SphereVertexOut {
    float4 position [[position]];
    float3 normal;      // Interpolated normal for smooth shading
    float4 color;
    float3 worldPos;
};

vertex SphereVertexOut smooth_sphere_vertex_shader(SphereVertex in [[stage_in]],
                                            constant float4x4 &mvpMatrix [[buffer(1)]],
                                            constant float3x3 &normalMatrix [[buffer(2)]]) {
    SphereVertexOut out;
    
    // Transform position
    out.position = mvpMatrix * float4(in.position, 1.0);
    
    // Transform normal (important for proper lighting under rotation)
    out.normal = normalMatrix * in.normal;
    
    out.color = in.color;
    out.worldPos = in.position;
    
    return out;
}

fragment float4 smooth_sphere_fragment_shader(SphereVertexOut in [[stage_in]]) {
    // Normalize the interpolated normal for smooth shading
    float3 normal = normalize(in.normal);
    
    // Multiple light sources for better appearance
    float3 lightDir1 = normalize(float3(1.0, 1.0, 1.0));   // Main light
    float3 lightDir2 = normalize(float3(-0.5, -0.2, 0.8)); // Fill light
    float3 lightDir3 = normalize(float3(0.0, -1.0, 0.0));  // Bottom light
    
    // Calculate lighting
    float diffuse1 = max(0.0, dot(normal, lightDir1)) * 0.6;
    float diffuse2 = max(0.0, dot(normal, lightDir2)) * 0.3;
    float diffuse3 = max(0.0, dot(normal, lightDir3)) * 0.1;
    
    float ambient = 0.2; // Ambient light
    
    float totalLight = ambient + diffuse1 + diffuse2 + diffuse3;
    totalLight = min(1.0, totalLight); // Clamp to prevent over-brightening
    
    // NEW: Enhanced Fresnel effect for stronger rim lighting/halo
    float3 viewDir = normalize(float3(0.0, 0.0, 1.0)); // Simplified view direction
    float fresnel = 1.0 - abs(dot(normal, viewDir));
    
    // NEW: Multiple fresnel layers for halo effect
    float halo1 = pow(fresnel, 1.5) * 0.8;  // Inner halo - bright
    float halo2 = pow(fresnel, 3.0) * 0.5;  // Outer halo - softer
    float halo3 = pow(fresnel, 6.0) * 0.3;  // Far halo - subtle
    
    // NEW: Combine halo effects with color tinting
    float3 haloColor1 = float3(1.0, 0.9, 0.7);  // Warm white
    float3 haloColor2 = float3(0.7, 0.8, 1.0);  // Cool blue
    float3 haloColor3 = float3(1.0, 0.6, 0.8);  // Pink tint
    
    float3 totalHalo = halo1 * haloColor1 + halo2 * haloColor2 + halo3 * haloColor3;
    
    // NEW: Add atmospheric scattering effect
    float distance = length(in.worldPos);
    float scattering = exp(-distance * 0.5) * 0.2;
    float3 scatterColor = float3(0.3, 0.5, 0.8) * scattering;
    
    // NEW: Pulse effect for dynamic halo
//    float pulse = sin(in.time * 2.0) * 0.1 + 0.9; // Subtle pulsing using passed time
    
    // NEW: Combine all effects
    float3 baseColor = in.color.rgb * totalLight;
    float3 finalColor = baseColor + totalHalo + scatterColor;
    
    // NEW: Add subtle bloom by increasing alpha on edges
    float edgeAlpha = 1.0 + (halo1 * 0.5); // Slight alpha increase on edges
    
    return float4(finalColor, in.color.a * edgeAlpha);
}
