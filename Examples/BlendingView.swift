import SwiftUI

struct BlendingView: View {
    
    @State private var isMovingRight = false
    
    @State private var blending: BlendMode = .plusLighter
    
    @State private var blur: Double = 30
    
    private let offset: CGFloat = 100
    private let blendModes: [(String, BlendMode)] = [
        ("Normal", .normal),
        ("Color", .color),
        ("Color Burn", .colorBurn),
        ("Color Dodge", .colorDodge),
        ("Darken", .darken),
        ("Destination Out", .destinationOut),
        ("Destination Over", .destinationOver),
        ("Difference", .difference),
        ("Exclusion", .exclusion),
        ("Hard Light", .hardLight),
        ("Hue", .hue),
        ("Lighten", .lighten),
        ("Luminosity", .luminosity),
        ("Multiply", .multiply),
        ("Overlay", .overlay),
        ("Plus Darker", .plusDarker),
        ("Plus Lighter", .plusLighter),
        ("Saturation", .saturation),
        ("Screen", .screen),
        ("Soft Light", .softLight),
        ("Source Atop", .sourceAtop)
    ]
    
    var body: some View {
        
        VStack{
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 100)
                    .blur(radius: 10)
                
                Circle()
                    .fill(.white)
                    .frame(width: 100)
                    .blur(radius: 10)
                
                ZStack {
//                    Circle()
//                        .fill(.white)
//                        .frame(width: 50)
//                        .blur(radius: blur/2)
                    Circle()
                        .fill(.yellow)
                        .frame(width: 150)
                        .blur(radius: blur)
                }
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 50)
                        .blur(radius: blur/2)
                    Circle()
                        .fill(.red)
                        .frame(width: 50)
                        .blur(radius: blur)
                }
                .offset(x: isMovingRight ? offset : -offset)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: isMovingRight
                )
                .onAppear {
                    isMovingRight = true
                }
            }
            .frame(height: 500)
            .blendMode(blending)
            
            HStack {
                Text("Blur")
                Slider(value: $blur, in: 0...50)
                Text("\(String(format: "%.2f", blur))")
            }
            
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 200))
                ], spacing: 5) {
                    ForEach(blendModes, id: \.1) { item in
                        Button(item.0) {
                            blending = item.1
                        }
                        .tint(.primary)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(8)
                    }
                }
            }
            
        }
        .preferredColorScheme(.dark)
        
    }
}

#Preview {
    BlendingView()
}
