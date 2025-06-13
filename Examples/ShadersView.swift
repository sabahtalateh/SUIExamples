import SwiftUI

struct ShadersView: View {
    
    @State private var initAt = Date()
    
    @State private var time: Float = 0
    
    var body: some View {
        VStack {
            Rectangle()
                .frame(width: 100, height: 100)
                .magenta()
//                .gradientSubtract()
            
            TimelineView(.animation) { _ in
                Image(systemName: "cloud.circle.fill")
                    .foregroundStyle(.cyan)
                    .font(.system(size: 100))
                    .colorEffect(ShaderLibrary.noise(.float(initAt.timeIntervalSinceNow)))
//                    .noise(seconds: initAt.timeIntervalSinceNow)
            }
            .frame(width: 100, height: 100)
            
            TimelineView(.animation) { _ in
                Image(systemName: "cloud.circle.fill")
                    .foregroundStyle(.cyan)
                    .font(.system(size: 100))
                    .colorEffect(ShaderLibrary.smoothNoise(.float(initAt.timeIntervalSinceNow)))
            }
            .frame(width: 100, height: 100)
        }
    }
    
}

extension View {
    func magenta() -> some View {
        let function = ShaderFunction(library: .default, name: "magenta")
        let shader = Shader(function: function, arguments: [])
        return colorEffect(shader)
    }
    
    func noise(seconds: Double) -> some View {
        let function = ShaderFunction(library: .default, name: "noise")
        let shader = Shader(
            function: function,
            arguments: [
                .float(seconds)
            ]
        )
        return colorEffect(shader)
    }
    
    func gradientSubtract() -> some View {
        return layerEffect(
            ShaderLibrary.default.gradientSubtract(.boundingRect),
            maxSampleOffset: .zero
        )
    }
}

#Preview {
    ShadersView()
}
