import SwiftUI
import MetalKit

struct CircleMetalView: UIViewRepresentable {
    
    private let device: MTLDevice!
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("fail to create Metal device")
        }
        self.device = device
    }
    
    func makeCoordinator() -> Coordinator {
        
        let c = Coordinator(
            device: device
        )
        
        return c
    }
    
    func makeUIView(context: Context) -> some UIView {
        
        let mtkView = MTKView()
        
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        
        mtkView.device = self.device
        
        // Allow to read GPU data. Needs for post processing (?)
        mtkView.framebufferOnly = false
        
        // Transparent background
        mtkView.backgroundColor = UIColor.clear
        mtkView.isOpaque = false
        
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

#Preview {
    ZStack {
        CircleMetalView()
    }
    .preferredColorScheme(.dark)
}


class Coordinator: NSObject, MTKViewDelegate {
    
    // Metal stuff
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    // Separate renderers for circle and particles
    private let circleRenderer: CircleRenderer
    
    // Keep track of time since last draw to update particle system
    private var lastDrawTime: CFTimeInterval = 0
    
    init(device: MTLDevice) {
        
        self.device = device
        
        guard let queue = device.makeCommandQueue() else {
            fatalError("fail to make Metal command queue")
        }
        self.commandQueue = queue
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("fail to make default shaders library")
        }
        
        self.circleRenderer = CircleRenderer(device: device, library: library)
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            circleRenderer.render(encoder: renderEncoder, radius: 0.4, center: SIMD2<Float>(0.1, -0.2))
            
            renderEncoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

class CircleRenderer {
    
    private let device: MTLDevice
    private let pipeline: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let radiusBuffer: MTLBuffer
    private let centerBuffer: MTLBuffer // NEW: Buffer for center coordinates
    
    init(device: MTLDevice, library: MTLLibrary) {
        
        self.device = device
        
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: Self.createPipelineDescriptor(library: library))
        } catch {
            fatalError("fail to make circle render pipeline: \(error)")
        }
        
        guard let buffer = device.makeBuffer(
            length: 4 * MemoryLayout<SIMD2<Float>>.stride,
            options: .storageModeShared
        ) else {
            fatalError("fail to create circle vertex buffer")
        }
        vertexBuffer = buffer
        
        guard let radiusBuf = device.makeBuffer(
            length: MemoryLayout<Float>.stride,
            options: .storageModeShared
        ) else {
            fatalError("fail to create radius buffer")
        }
        radiusBuffer = radiusBuf
        
        guard let centerBuf = device.makeBuffer(
            length: MemoryLayout<SIMD2<Float>>.stride,
            options: .storageModeShared
        ) else {
            fatalError("fail to create center buffer")
        }
        centerBuffer = centerBuf
    }
    
    private static func createPipelineDescriptor(library: MTLLibrary) -> MTLRenderPipelineDescriptor {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.vertexFunction = library.makeFunction(name: "circle_vertices")
        descriptor.fragmentFunction = library.makeFunction(name: "circle_fragments")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable blending for transparency
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return descriptor
    }
    
    func render(encoder: MTLRenderCommandEncoder, radius: Float, center: SIMD2<Float> = SIMD2<Float>(0, 0)) { // NEW: Added center parameter with default value
        
        let bufferPointer = vertexBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: 4)

        // NEW: Offset vertices by center coordinates
        bufferPointer[0] = SIMD2<Float>(-radius + center.x, -radius + center.y)  // Bottom left
        bufferPointer[1] = SIMD2<Float>( radius + center.x, -radius + center.y)  // Bottom right
        bufferPointer[2] = SIMD2<Float>(-radius + center.x,  radius + center.y)  // Top left
        bufferPointer[3] = SIMD2<Float>( radius + center.x,  radius + center.y)  // Top right
        
        // Set radius in buffer
        let radiusPointer = radiusBuffer.contents().bindMemory(to: Float.self, capacity: 1)
        radiusPointer[0] = radius
        
        // Set center coordinates in buffer
        let centerPointer = centerBuffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: 1)
        centerPointer[0] = center
        
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(radiusBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(centerBuffer, offset: 0, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
    
}
