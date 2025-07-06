import SwiftUI
import MetalKit

struct MetalKitCubeView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        // Setup MetalKit view
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        // Enable depth testing
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.colorPixelFormat = .bgra8Unorm
        
        // Clear colors
        mtkView.clearDepth = 1.0
        mtkView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Handle updates if needed
    }
    
    func makeCoordinator() -> MetalKitCubeRenderer {
        MetalKitCubeRenderer()
    }
}

struct CubeVertex {
    let position: SIMD3<Float>
    let color: SIMD4<Float>
}

struct CubeUniforms {
    let mvpMatrix: matrix_float4x4
}

class MetalKitCubeRenderer: NSObject, MTKViewDelegate {
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    
    // Vertex data
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    
    // Animation
    private var rotationAngle: Float = 0
    
    override init() {
        super.init()
        setupMetal()
        setupBuffers()
        setupPipeline()
        setupDepthStencil()
    }
    
    private func setupMetal() {
        // Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported on this device")
        }
        self.device = device
        
        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = commandQueue
    }
    
    private func setupBuffers() {
        // Cube vertices with colors
        let vertices: [CubeVertex] = [
            // Front face (Red)
            CubeVertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD4(1, 0, 0, 1)),
            CubeVertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD4(1, 0, 0, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD4(1, 0, 0, 1)),
            CubeVertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD4(1, 0, 0, 1)),
            
            // Back face (Green)
            CubeVertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD4(0, 1, 0, 1)),
            CubeVertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD4(0, 1, 0, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD4(0, 1, 0, 1)),
            CubeVertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD4(0, 1, 0, 1)),
            
            // Left face (Blue)
            CubeVertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD4(0, 0, 1, 1)),
            CubeVertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD4(0, 0, 1, 1)),
            CubeVertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD4(0, 0, 1, 1)),
            CubeVertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD4(0, 0, 1, 1)),
            
            // Right face (Yellow)
            CubeVertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD4(1, 1, 0, 1)),
            CubeVertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD4(1, 1, 0, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD4(1, 1, 0, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD4(1, 1, 0, 1)),
            
            // Top face (Magenta)
            CubeVertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD4(1, 0, 1, 1)),
            CubeVertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD4(1, 0, 1, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD4(1, 0, 1, 1)),
            CubeVertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD4(1, 0, 1, 1)),
            
            // Bottom face (Cyan)
            CubeVertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD4(0, 1, 1, 1)),
            CubeVertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD4(0, 1, 1, 1)),
            CubeVertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD4(0, 1, 1, 1)),
            CubeVertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD4(0, 1, 1, 1))
        ]
        
        // Create vertex buffer
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<CubeVertex>.stride,
            options: .storageModeShared
        )
        
        // Cube indices (2 triangles per face, 6 faces)
        let indices: [UInt16] = [
            0,  1,  2,   2,  3,  0,   // Front
            4,  6,  5,   6,  4,  7,   // Back
            8,  9, 10,  10, 11,  8,   // Left
           12, 14, 13,  14, 12, 15,   // Right
           16, 17, 18,  18, 19, 16,   // Top
           20, 22, 21,  22, 20, 23    // Bottom
        ]
        
        // Create index buffer
        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.stride,
            options: .storageModeShared
        )
    }
    
    private func setupPipeline() {
        // Get default library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default library")
        }
        
        // Get shader functions
        guard let vertexFunction = library.makeFunction(name: "metalkit_cube_vertex"),
              let fragmentFunction = library.makeFunction(name: "metalkit_cube_fragment") else {
            fatalError("Could not load shader functions")
        }
        
        // Create vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Color attribute
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<CubeVertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Create pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // Create pipeline state
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
    }
    
    private func setupDepthStencil() {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes if needed
    }
    
    func draw(in view: MTKView) {
        // Get command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // Set pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        // Set vertex buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Calculate matrices
        let aspect = Float(view.bounds.width / view.bounds.height)
        let mvpMatrix = createMVPMatrix(aspect: aspect)
        
        // Set uniforms
        var uniforms = CubeUniforms(mvpMatrix: mvpMatrix)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<CubeUniforms>.stride, index: 1)
        
        // Draw indexed triangles
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 36,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        
        // End encoding
        renderEncoder.endEncoding()
        
        // Present drawable
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        // Commit command buffer
        commandBuffer.commit()
        
        // Update rotation
        rotationAngle += 0.005
    }
    
    private func createMVPMatrix(aspect: Float) -> matrix_float4x4 {
        // Model matrix (rotation)
        let modelMatrix = matrix4x4_rotation(radians: rotationAngle, axis: SIMD3(1, 1, 0))
        
        // View matrix (camera)
        let viewMatrix = matrix4x4_translation(0, 0, -5)
        
        // Projection matrix
        let projectionMatrix = matrix4x4_perspective(
            fovyRadians: Float(Angle.degrees(60).radians),
            aspect: aspect,
            nearZ: 0.1,
            farZ: 100
        )
        
        return projectionMatrix * viewMatrix * modelMatrix
    }
}

func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    
    return matrix_float4x4(columns:(
        SIMD4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
        SIMD4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
        SIMD4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
        SIMD4(                  0,                   0,                   0, 1)
    ))
}

func matrix4x4_translation(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
    return matrix_float4x4(columns:(
        SIMD4(1, 0, 0, 0),
        SIMD4(0, 1, 0, 0),
        SIMD4(0, 0, 1, 0),
        SIMD4(x, y, z, 1)
    ))
}

func matrix4x4_perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovyRadians * 0.5)
    let xs = ys / aspect
    let zs = farZ / (nearZ - farZ)
    
    return matrix_float4x4(columns:(
        SIMD4(xs,  0, 0,   0),
        SIMD4( 0, ys, 0,   0),
        SIMD4( 0,  0, zs, -1),
        SIMD4( 0,  0, zs * nearZ, 0)
    ))
}

#Preview {
    MetalKitCubeView()
}
