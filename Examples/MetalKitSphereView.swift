import SwiftUI
import MetalKit

struct MetalKitSphereView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) // NEW: Black background for better halo visibility
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Updates if needed
    }
    
    func makeCoordinator() -> SphereCoordinator {
        SphereCoordinator()
    }
}

class SphereCoordinator: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var sphereRenderer: SphereRenderer!
    private var depthStencilState: MTLDepthStencilState!
    private var rotationAngle: Float = 0
    
    override init() {
        super.init()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.sphereRenderer = SphereRenderer(device: device, radius: 0.3, rings: 60, sectors: 60)
        
        // Setup depth testing
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        encoder.setDepthStencilState(depthStencilState)
        
        let aspect = Float(view.bounds.width / view.bounds.height)
        let (mvpMatrix, normalMatrix) = createMatrices(aspect: aspect)
        
        sphereRenderer.render(encoder: encoder, mvpMatrix: mvpMatrix, normalMatrix: normalMatrix)
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func createMatrices(aspect: Float) -> (matrix_float4x4, matrix_float3x3) {
        rotationAngle += 0 // Static rotation for now
        
        // NEW: Create rotation matrix
        let rotationMatrix = matrix4x4_rotation(radians: rotationAngle, axis: SIMD3(0, 1, 0))
        
        // NEW: Create translation matrix using sphere center position
        let translationMatrix = matrix4x4_translation(0, 0, 0)
//        let translationMatrix = matrix4x4_translation(sphereCenter.x, sphereCenter.y, sphereCenter.z)
        
        // NEW: Combine transformations (translation then rotation)
        let modelMatrix = translationMatrix * rotationMatrix
        
        let viewMatrix = matrix4x4_translation(0, 0, -3)
        let projectionMatrix = matrix4x4_perspective(
            fovyRadians: Float.pi / 4,
            aspect: aspect,
            nearZ: 0.1,
            farZ: 100
        )
        
        let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix
        let normalMatrix = matrix3x3_from_4x4(rotationMatrix) // NEW: Use only rotation for normals
        
        return (mvpMatrix, normalMatrix)
    }
}

func matrix3x3_from_4x4(_ matrix: matrix_float4x4) -> matrix_float3x3 {
    return matrix_float3x3(columns: (
        SIMD3(matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z),
        SIMD3(matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z),
        SIMD3(matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z)
    ))
}

struct SphereVertex {
    let position: SIMD3<Float>
    let normal: SIMD3<Float>
    let color: SIMD4<Float>
}

class SphereRenderer {
    private let device: MTLDevice
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let pipelineState: MTLRenderPipelineState
    private let indexCount: Int
    
    init(device: MTLDevice, radius: Float = 0.5, rings: Int = 40, sectors: Int = 40) {
        self.device = device
        
        var vertices: [SphereVertex] = []
        var indices: [UInt16] = []
        
        // Generate sphere vertices with proper normals
        for ring in 0...rings {
            let phi = Float.pi * Float(ring) / Float(rings)
            let y = cos(phi) * radius
            let ringRadius = sin(phi) * radius
            
            for sector in 0...sectors {
                let theta = 2.0 * Float.pi * Float(sector) / Float(sectors)
                let x = cos(theta) * ringRadius
                let z = sin(theta) * ringRadius
                
                let position = SIMD3(x, y, z)
                let normal = normalize(position)
                
                // NEW: Enhanced color gradient for better halo effect
                let color = SIMD4<Float>(
                    0.3 + (normal.x + 1.0) * 0.35,  // Subtle red gradient
                    0.4 + (normal.y + 1.0) * 0.3,   // Subtle green gradient
                    0.6 + (normal.z + 1.0) * 0.4,   // More blue for cooler tone
                    1.0
                )
                
                vertices.append(SphereVertex(
                    position: position,
                    normal: normal,
                    color: color
                ))
            }
        }
        
        // Generate sphere indices
        for ring in 0..<rings {
            for sector in 0..<sectors {
                let first = UInt16(ring * (sectors + 1) + sector)
                let second = UInt16(first + UInt16(sectors + 1))
                
                indices.append(first)
                indices.append(second)
                indices.append(first + 1)
                
                indices.append(second)
                indices.append(second + 1)
                indices.append(first + 1)
            }
        }
        
        self.indexCount = indices.count
        
        // Create vertex buffer
        self.vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<SphereVertex>.stride,
            options: .storageModeShared
        )!
        
        // Create index buffer
        self.indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: .storageModeShared
        )!
        
        // Create render pipeline
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "smooth_sphere_vertex_shader")
        let fragmentFunction = library.makeFunction(name: "smooth_sphere_fragment_shader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // NEW: Enable blending for halo effect
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // Updated vertex descriptor with normal
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute (attribute 0)
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Normal attribute (attribute 1)
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Color attribute (attribute 2)
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride * 2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        // Layout for buffer 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SphereVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func render(encoder: MTLRenderCommandEncoder, mvpMatrix: matrix_float4x4, normalMatrix: matrix_float3x3) {
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Set matrices
        var mvp = mvpMatrix
        var normal = normalMatrix
        
        encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
        encoder.setVertexBytes(&normal, length: MemoryLayout<matrix_float3x3>.size, index: 2)
        
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
    }
}
