import SwiftUI

struct GradientSubtractView: View {
    
    @State private var offset: Float = 0.5
    
    var body: some View {
        ScrollView {
            VStack {
                
                Text("Gradient Subtract Shader")
                    .font(.title)
                    .bold()
                
                HStack {
                    VStack {
                        Text("Original")
                            .font(.headline)
                        SampleImage()
                    }
                    
                    VStack {
                        Text("With Shader")
                            .font(.headline)
                        SampleImage()
                            .layerEffect(
                                ShaderLibrary.gradientSubtract(.boundingRect, .float(offset)),
                                maxSampleOffset: .zero
                            )
                    }
                }
                
                HStack {
                    Text("Offset: \(offset, specifier: "%.2f")")
                    Slider(value: $offset, in: 0...1)
                }
                .padding(.horizontal)
                
                // Step by step explanation
//                VStack(alignment: .leading, spacing: 15) {
//                    Text("How it works:")
//                        .font(.title2)
//                        .bold()
//                    
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text("1. **Position to UV conversion:**")
//                        Text("   `float2 uv = position / bounds.zw`")
//                        Text("   Converts pixel position to 0-1 coordinates")
//                        
//                        Text("2. **Sample current color:**")
//                        Text("   `half4 pixelColor = layer.sample(position)`")
//                        Text("   Gets the original pixel color")
//                        
//                        Text("3. **Calculate gradient:**")
//                        Text("   `uv.x * offset` - horizontal gradient (0 to offset)")
//                        Text("   `uv.y * offset` - vertical gradient (0 to offset)")
//                        
//                        Text("4. **Subtract gradient:**")
//                        Text("   `pixelColor - half4(gradX, gradY, 0, 0)`")
//                        Text("   Subtracts red and green based on position")
//                    }
//                }
//                .padding()
//                .background(Color.blue.opacity(0.1))
//                .cornerRadius(10)
                
                // Visual breakdown
//                VStack {
//                    Text("Visual Breakdown")
//                        .font(.title2)
//                        .bold()
//                    
//                    HStack {
//                        VStack {
//                            Text("Red Gradient")
//                                .font(.caption)
//                            Rectangle()
//                                .fill(LinearGradient(
//                                    colors: [.black, .red],
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                ))
//                                .frame(width: 80, height: 60)
//                            Text("uv.x * offset")
//                                .font(.caption2)
//                        }
//                        
//                        Text("−")
//                            .font(.title)
//                        
//                        VStack {
//                            Text("Green Gradient")
//                                .font(.caption)
//                            Rectangle()
//                                .fill(LinearGradient(
//                                    colors: [.black, .green],
//                                    startPoint: .top,
//                                    endPoint: .bottom
//                                ))
//                                .frame(width: 80, height: 60)
//                            Text("uv.y * offset")
//                                .font(.caption2)
//                        }
//                    }
//                }
                
                // Different offset examples
                VStack {
                    Text("Different Offset Values")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        VStack {
                            Text("Offset: 0.0")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.gradientSubtract(.boundingRect, .float(0.0)),
                                    maxSampleOffset: .zero
                                )
                        }
                        
                        VStack {
                            Text("Offset: 0.3")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.gradientSubtract(.boundingRect, .float(0.3)),
                                    maxSampleOffset: .zero
                                )
                        }
                        
                        VStack {
                            Text("Offset: 0.7")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.gradientSubtract(.boundingRect, .float(0.7)),
                                    maxSampleOffset: .zero
                                )
                        }
                        
                        VStack {
                            Text("Offset: 1.0")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.gradientSubtract(.boundingRect, .float(1.0)),
                                    maxSampleOffset: .zero
                                )
                        }
                    }
                }
                
                // Use cases
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Common Use Cases:")
//                        .font(.title2)
//                        .bold()
//                    
//                    Text("• **Vintage/Film effects** - simulates old film grain")
//                    Text("• **Color grading** - selective color reduction")
//                    Text("• **Artistic filters** - creates specific mood")
//                    Text("• **UI effects** - directional color fading")
//                    Text("• **Vignette alternatives** - edge darkening")
//                }
//                .padding()
//                .background(Color.green.opacity(0.1))
//                .cornerRadius(10)
//                
//                // Variations
                VStack {
                    Text("Shader Variations")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        VStack {
                            Text("Radial Subtract")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.radialSubtract(.boundingRect, .float(offset)),
                                    maxSampleOffset: .zero
                                )
                        }
                        
                        VStack {
                            Text("Blue Channel")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.blueSubtract(.boundingRect, .float(offset)),
                                    maxSampleOffset: .zero
                                )
                        }
                        
                        VStack {
                            Text("Diagonal")
                                .font(.caption)
                            SampleImage()
                                .layerEffect(
                                    ShaderLibrary.diagonalSubtract(.boundingRect, .float(offset)),
                                    maxSampleOffset: .zero
                                )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct SampleImage: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.red, .orange, .yellow, .green, .blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                Text("TEST")
                    .foregroundColor(.white)
                    .font(.headline)
                    .bold()
            }
            .padding()
        }
        
        //        .frame(width: 120, height: 80)
        .cornerRadius(16)
    }
}

#Preview {
    GradientSubtractView()
}

