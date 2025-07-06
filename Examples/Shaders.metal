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

[[stitchable]] float2 wave(float2 position, float time, float vel, float freq, float amp) {
    float positionY = position.y + sin((time * vel) + (position.x / freq) ) * amp;
    return float2(position.x, positionY);
}

// return value [0, 1]
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float getRandomAngle(float seed) {
    // hash дает 0-1, умножаем на 2π для полного круга
    return hash(seed) * 6.28318; // 2π радиан = 360°
}

[[stitchable]] half4 singleRandomParticle(float2 position, SwiftUI::Layer layer, float4 bounds, float seed) {
    
    
    
    // Convert position to UV coordinates (0-1)
    float2 uv = position / bounds.zw;
    
    // Исправляем aspect ratio
    float aspectRatio = bounds.z / bounds.w; // width / height

    uv.x *= aspectRatio; // Растягиваем X координату
    
    // Центр
    float2 center = float2(0.5 * aspectRatio, 0.5);
    
    // Радиус окружности (в UV координатах)
    float circleRadius = 0.2;
    
    // Начальный угол для частицы (можно изменить для разных направлений)
    float startAngle = 45 * 0.01745329; // Начинаем справа
    
    // Стартовая позиция на краю окружности
    float2 startPos = center + float2(cos(startAngle), sin(startAngle)) * circleRadius;
    
    // Целевая позиция (центр)
    float2 endPos = center;
    
    // Время движения (2 секунды на полный цикл)
//    float moveTime = 2.0;
    // float normalizedTime = fmod(time, moveTime) / moveTime; // 0 to 1
    float normalizedTime = 0;
    
    // Текущая позиция частицы (линейная интерполяция)
    float2 currentPos = mix(startPos, endPos, normalizedTime);
    
    // Размер частицы
    float particleSize = 0.005;
    
    // Проверяем расстояние от текущего пикселя до частицы
    float distanceToParticle = length(uv - currentPos);
    
    if (distanceToParticle <= particleSize) {
        return half4(1, 1, 1, 1);
    }
    
    // Рисуем окружность для понимания границ (опционально)
    float distanceToCircle = abs(length(uv - center) - circleRadius);
    if (distanceToCircle < 0.001) { // Тонкая линия
        return half4(0.3, 0.3, 0.3, 1.0); // Серая окружность
    }
    
    //    float2 center = float2(0.5 * aspectRatio, 0.5);
    //
    //    // Радиус частицы в UV координатах
    //    float particleRadius = 0.05 * aspectRatio; // 10% от области
    //
    //    // Вычисляем расстояние в UV пространстве
    //    float distance = length(uv - center);
    //
    //    // Если пиксель внутри радиуса - рисуем белую частицу
    //    if (distance <= particleRadius) {
    //        return half4(1.0, 1.0, 1.0, 1.0); // Белый цвет
    //    }
    
    return half4(0, 0, 0, 0);
}

// FRAGMENT SHADER - рисует красный круг
[[stitchable]] half4 redCircle(float2 position, SwiftUI::Layer layer, float4 bounds) {
    float2 center = bounds.zw * 0.5;
    float distance = length(position - center);
    
    if (distance < 50.0) {
        return half4(1, 0, 0, 1); // Красный
    }
    return half4(0, 0, 0, 1); // Черный
}

// COMPUTE SHADER - умножает числа на 2
[[kernel]] void multiplyByTwo(device float* data [[buffer(0)]], uint id [[thread_position_in_grid]]) {
    if (id < 5) {
        data[id] = data[id] * 2.0;
    }
}

struct Particle {
    float x, y, vx, vy;
};

// COMPUTE SHADER - обновляет физику частиц
[[kernel]] void moveParticles(device Particle* particles [[buffer(0)]], uint id [[thread_position_in_grid]]) {
    if (id >= 10) return;
    
    // NEW CODE: Добавлен device address space qualifier
    device Particle& p = particles[id];
    
    // Обновляем позицию
    p.x += p.vx;
    p.y += p.vy;
    
    // Отражение от границ
    if (p.x <= 0.0 || p.x >= 1.0) {
        p.vx *= -1.0;
        p.x = clamp(p.x, 0.0, 1.0);
    }
    
    if (p.y <= 0.0 || p.y >= 1.0) {
        p.vy *= -1.0;
        p.y = clamp(p.y, 0.0, 1.0);
    }
}

// FRAGMENT SHADER - читает данные частиц через floatArray
[[stitchable]] half4 renderMovingParticles(float2 position, SwiftUI::Layer layer, float4 bounds, device const float* particlePositions) {
//    float2 uv = position / bounds.zw;
//    float aspectRatio = bounds.z / bounds.w;
//    uv.x *= aspectRatio;
//    
//    // Проверяем каждую частицу (данные: x1,y1,x2,y2,x3,y3...)
//    for (int i = 0; i < 20; i += 2) { // 10 частиц × 2 координаты
//        float particleX = particlePositions[i];
//        float particleY = particlePositions[i + 1];
//        
//        // Если частица не инициализирована
//        if (particleX == 0.0 && particleY == 0.0) continue;
//        
//        float2 particlePos = float2(particleX * aspectRatio, particleY);
//        float distance = length(uv - particlePos);
//        
//        if (distance < 0.03) {
//            // Цвет зависит от номера частицы
//            float particleIndex = float(i / 2);
//            return half4(
//                0.5 + 0.5 * sin(particleIndex),
//                0.5 + 0.5 * cos(particleIndex),
//                1.0,
//                1.0
//            );
//        }
//    }
    
    return half4(0.5, 0.5, 0.0, 1.0);
}



//constant float4 positions[] = {
//    float4(-0.75, -0.5, 0.0, 1.0), //bottom left: red
//    float4( 0.75, -0.5, 0.0, 1.0), //bottom right: green
//    float4(  0.0,  0.75, 0.0, 1.0), //center top: blue
//    
//    float4(-0.75, 0.5, 0.0, 1.0), //bottom left: red
//    float4( 0.75, 0.5, 0.0, 1.0), //bottom right: green
//    float4(  0.0,  -0.75, 0.0, 1.0), //center top: blue
//};
//
//constant half4 colors[] = {
//    half4(1.0, 0.0, 0.0, 0.5), //bottom left: red
//    half4(0.0, 1.0, 0.0, 0.5), //bottom right: green
//    half4(0.0, 0.0, 1.0, 1), //center top: blue
//    
//    half4(0.0, 1.0, 0.0, 0.5), //bottom right: green
//    half4(1.0, 0.0, 0.0, 0.5), //bottom left: red
//    half4(0.0, 0.0, 1.0, 1), //center top: blue
//};

//VertexPayload vertex vertexMain(uint i [[vertex_id]]) {
//    VertexPayload payload;
//    payload.position = positions[i];
//    payload.color = colors[i];
//    return payload;
//}




//struct VertexPayload {              //Mesh Vertex Type
//    float4 position [[position]];   //Qualified attribute
//    half4 color;                    //Half precision, faster
//};
//
//struct VertexData {
//    float4 position;
//    half4 color;
//};
//
//// COMPUTE SHADER - simple hardcoded positions, no parameters
//kernel void computePositions(uint id [[thread_position_in_grid]],
//                            device float4* dynamicPositions [[buffer(0)]]) {
//    
//    // Hardcoded triangle positions
//    float4 hardcodedPositions[6] = {
//        float4(-0.5, -0.5, 0.0, 1.0),  // Triangle 1
//        float4( 0.5, -0.5, 0.0, 1.0),
//        float4( 0.0,  0.5, 0.0, 1.0),
//        
//        float4(-0.8,  0.3, 0.0, 1.0),  // Triangle 2
//        float4( 0.8,  0.3, 0.0, 1.0),
//        float4( 0.0, -0.8, 0.0, 1.0),
//    };
//    
//    // Simply output the hardcoded position for this vertex
//    if (id < 6) {
//        dynamicPositions[id] = hardcodedPositions[id];
//    }
//}
//
//// VERTEX SHADER - receives computed positions
//VertexPayload vertex vertexMain2(uint vertexID [[vertex_id]],
//                               constant float4* positions [[buffer(0)]],
//                               constant half4* colors [[buffer(1)]]) {
//    
//    VertexPayload payload;
//    payload.position = positions[vertexID];
//    payload.color = colors[vertexID];
//    
//    return payload;
//}
//
//VertexPayload vertex vertexMain(uint i [[vertex_id]],
//                               constant VertexData* vertexData [[buffer(0)]]) {
//    VertexPayload payload;
//    payload.position = vertexData[i].position;
//    payload.color = vertexData[i].color;
//    return payload;
//}
//
//// FRAGMENT SHADER - renders pixels
//half4 fragment fragmentMain(VertexPayload frag [[stage_in]]) {
//    return frag.color;
//}




// Структура для передачи данных между шейдерами
//struct VertexOut {
//    float4 position [[position]];
//    half4 color;
//};
//
//// COMPUTE SHADER - генерирует 3 точки треугольника
//kernel void computePositions(uint id [[thread_position_in_grid]],
//                            device float4* positions [[buffer(0)]]) {
//    
//    // Проверяем, что id не выходит за границы
//    if (id >= 3) return;
//    
//    // Создаем простой треугольник
//    if (id == 0) {
//        positions[0] = float4(-0.5, -0.5, 0.0, 1.0); // левый нижний
//    } else if (id == 1) {
//        positions[1] = float4(0.5, -0.5, 0.0, 1.0);  // правый нижний
//    } else if (id == 2) {
//        positions[2] = float4(0.0, 0.5, 0.0, 1.0);   // верхний
//    }
//}
//
//// VERTEX SHADER - просто передает данные дальше
//vertex VertexOut vertexMain(uint vertexID [[vertex_id]],
//                           constant float4* positions [[buffer(0)]],
//                           constant half4* colors [[buffer(1)]]) {
//    
//    VertexOut out;
//    out.position = positions[vertexID];
//    out.color = colors[vertexID];
//    return out;
//}
//
//fragment half4 fragmentMain(VertexOut in [[stage_in]]) {
//    return in.color;
//}
