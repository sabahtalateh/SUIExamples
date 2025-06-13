#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;


[[stitchable]] half4 magenta(float2 position, half4 currentColor) {
    return half4(199.0/255.0, 85.0/255.0, 212.0/255.0, 1.0);
}

[[stitchable]] half4 noise(float2 position, half4 currentColor, float time) {
//    float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    float value = fract(sin(dot(position + time, float2(12.9898, 78.233))) * 43758.5453);
    return half4(value, value, value, 1) * currentColor.a;
}

[[stitchable]] half4 smoothNoise(float2 position, half4 currentColor, float time) {
    float2 scaledPos = position * 0.01; // Scale down for smoother noise
    float value = fract(sin(dot(scaledPos + time * 0.1, float2(12.9898, 78.233))) * 43758.5453);
    
    // Blend with original color
    return mix(currentColor, half4(value, value, value, 1), 0.3);
}

//[[stitchable]] half4 gradientSubtract(float2 position, SwiftUI::Layer layer, float4 bounds) {
//    float2 uv = position / bounds.zw;
//    half4 pixelColor = layer.sample(position);
//    float offset = 0.5;
//    return  pixelColor - half4(uv.x * offset, uv.y * offset, 0, 0);
//}

// Original gradient subtract shader
[[stitchable]] half4 gradientSubtract(float2 position, SwiftUI::Layer layer, float4 bounds, float offset) {
    
    // Convert position to UV coordinates (0-1)
    float2 uv = position / bounds.zw;
    
    // Sample the original pixel color
    half4 pixelColor = layer.sample(position);
    
    // Create gradients:
    // uv.x goes from 0 (left) to 1 (right)
    // uv.y goes from 0 (top) to 1 (bottom)
    float redGradient = uv.x * offset;    // 0 to offset horizontally
    float greenGradient = uv.y * offset;  // 0 to offset vertically
    
    // Subtract gradients from red and green channels
    // Blue and alpha remain unchanged
    return pixelColor - half4(redGradient, greenGradient, 0, 0);
}

// Variation 1: Radial subtract (from center)
[[stitchable]] half4 radialSubtract(float2 position, SwiftUI::Layer layer, float4 bounds, float offset) {

    float2 uv = position / bounds.zw;
    float2 center = float2(0.5, 0.5);
    
    // Distance from center (0 to ~0.7)
    float distanceFromCenter = length(uv - center);
    
    half4 pixelColor = layer.sample(position);
    
    // Subtract based on distance from center
    float subtract = distanceFromCenter * offset;
    return pixelColor - half4(subtract, subtract, subtract, 0);
}

// Variation 2: Blue channel subtract
[[stitchable]] half4 blueSubtract(float2 position, SwiftUI::Layer layer, float4 bounds, float offset) {
    float2 uv = position / bounds.zw;
    
    half4 pixelColor = layer.sample(position);
    
    // Subtract from blue channel only, based on diagonal
    float blueGradient = (uv.x + uv.y) * 0.5 * offset;
    return pixelColor - half4(0, 0, blueGradient, 0);
}

// Variation 3: Diagonal subtract
[[stitchable]] half4 diagonalSubtract(float2 position, SwiftUI::Layer layer, float4 bounds, float offset) {
    float2 uv = position / bounds.zw;
    
    half4 pixelColor = layer.sample(position);
    
    // Diagonal gradient (top-left to bottom-right)
    float diagonal = (uv.x + uv.y) * 0.5 * offset;
    return pixelColor - half4(diagonal, diagonal * 0.5, 0, 0);
}
