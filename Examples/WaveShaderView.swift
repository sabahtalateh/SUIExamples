import SwiftUI

struct WaveShaderView: View {
    
    private let initAt: Date = .now
    
    @State var vel: Double = 5
    @State var freq: Double = 20
    @State var amp: Double = 3
    
    var body: some View {
        TimelineView(.animation) { _ in
            
//            Text("\(ctx.date.timeIntervalSince1970)")
            
            Image(systemName: "cloud.circle.fill")
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .red]), startPoint: .leading, endPoint: .trailing))
                .font(.system(size: 300))
                .distortionEffect(ShaderLibrary.wave(
                    .float(initAt.timeIntervalSinceNow),
                    .float(vel),
                    .float(freq),
                    .float(amp)
                ), maxSampleOffset: .zero)
        }
         
        VStack {
            VStack {
                Text("Velocity: \(vel)")
                Slider(value: $vel, in: 0...100)
            }
            
            VStack {
                Text("Frequency: \(freq)")
                Slider(value: $freq, in: 1...100)
            }
            
            VStack {
                Text("Amplitude: \(amp)")
                Slider(value: $amp, in: 1...100)
            }
        }
        .padding()
    }
}

#Preview {
    WaveShaderView()
}
