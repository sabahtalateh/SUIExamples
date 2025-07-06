import SwiftUI
import Metal

class MinimalGPU: ObservableObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var computePipeline: MTLComputePipelineState!
    private var dataBuffer: MTLBuffer!
    
    @Published var numbers: [Float] = [1, 2, 3, 4, 5]
    
    init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        
        // Создаем compute pipeline
        let library = device.makeDefaultLibrary()!
        let function = library.makeFunction(name: "multiplyByTwo")!
        computePipeline = try! device.makeComputePipelineState(function: function)
        
        // Создаем буфер
        dataBuffer = device.makeBuffer(bytes: numbers, length: numbers.count * 4, options: .storageModeShared)!
    }
    
    func runCompute() {
        // Запускаем compute shader
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        
        encoder.setComputePipelineState(computePipeline)
        encoder.setBuffer(dataBuffer, offset: 0, index: 0)
        encoder.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1),
                                   threadsPerThreadgroup: MTLSize(width: 5, height: 1, depth: 1))
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Читаем результат
        let pointer = dataBuffer.contents().bindMemory(to: Float.self, capacity: 5)
        numbers = Array(UnsafeBufferPointer(start: pointer, count: 5))
    }
}

struct MinimalShadersView: View {
    @StateObject private var gpu = MinimalGPU()
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("Fragment + Compute шейдеры")
                .font(.title)
            
            // Fragment shader - рисует красный круг
            Rectangle()
                .fill(Color.black)
                .frame(width: 200, height: 200)
                .layerEffect(ShaderLibrary.redCircle(.boundingRect), maxSampleOffset: .zero)
            
            // Compute shader результат
            VStack {
                Text("Compute результат:")
                Text("\(gpu.numbers.map { String(Int($0)) }.joined(separator: ", "))")
                    .font(.headline)
                
                Button("Умножить на 2") {
                    gpu.runCompute()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    MinimalShadersView()
}
