//
//  Renderer.swift
//  hello-3d-box
//
//  Created by Rhys Balevicius.
//

import MetalKit

class Renderer : NSObject
{
    // MARK: - Private properties
    private var metalKitView           : MTKView!
    private var device                 : MTLDevice!
    private var commandQueue           : MTLCommandQueue!
    private var pipelineState          : MTLRenderPipelineState!
    private var vertexBuffer           : MTLBuffer!
    private var uniformBuffer          : MTLBuffer!
    private var indexBuffer            : MTLBuffer!
    
    private var rotation : Float = 0
//    private var lastRenderTime : CFTimeInterval?
//    private var currentTime    : Double = 0
    private let gpuLock = DispatchSemaphore(value: 1)
    
    // MARK: - Lifecycle
    init?(metalKitView: MTKView)
    {
        super.init()
        
        self.metalKitView = metalKitView
        
        // Represents the actual GPU
        self.device = metalKitView.device!
        
        // An `MTLCommandQueue` keeps track of many `MTLCommandBuffer` objects
        // that are waiting to be executed.
        self.commandQueue = device.makeCommandQueue()!
        
        // Create the render pipeline
        do {
            pipelineState = try buildRenderPipelineWith(device: device, metalKitView: metalKitView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
    }
    
    // MARK: - Private functions
    private func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState
    {
        // Register the shaders in the pipeline
        let (vertexShader, fragmentShader) = registerShaders()
        
        // Setup a new pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexShader
        pipelineDescriptor.fragmentFunction = fragmentShader

        // Setup the output pixel format to match the pixel format of the metal kit view
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        createBuffer() // Our drawable data
        
        // Try to compile the configure pipeline descriptor to a pipeline state object
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private func createBuffer()
    {
        let vertexData = [
            Vertex([-1.0, -1.0,  0.0, 1.0], [1, 0, 0, 1]),
            Vertex([ 1.0, -1.0,  0.0, 1.0], [0, 1, 0, 1]),
            Vertex([ 1.0,  1.0,  0.0, 1.0], [0, 0, 1, 1]),
            Vertex([-1.0,  1.0,  0.0, 1.0], [1, 1, 1, 1]),
            Vertex([-1.0, -1.0, -1.0, 1.0], [0, 0, 1, 1]),
            Vertex([ 1.0, -1.0, -1.0, 1.0], [1, 1, 1, 1]),
            Vertex([ 1.0,  1.0, -1.0, 1.0], [1, 0, 0, 1]),
            Vertex([-1.0,  1.0, -1.0, 1.0], [0, 1, 0, 1]),
        ]
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: vertexData.count * MemoryLayout<Vertex>.stride,
            options: [])
        
        
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.stride,
            options: [])

//        let modelMatrix = Matrix.modelMatrix()
//        let viewMatrix = Matrix.viewMatrix()
//        let projMatrix = Matrix.projectionMatrix(near: 1, far: 100, aspect: 1, fovy: 1)
//
//        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
//        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
//
//        let bufferPointer = uniformBuffer.contents()
//        memcpy(
//            bufferPointer,
//            &uniforms,
//            MemoryLayout<Uniforms>.stride)
        
//        uniformBuffer = device.makeBuffer(
//            length: MemoryLayout<Float>.stride * 16,
//            options: [])
//
//        let bufferPointer = uniformBuffer.contents()
//        memcpy(
//            bufferPointer,
//            Matrix().model(matrix: Matrix()).m,
//            MemoryLayout<Float>.stride * 16)

        
        let indexData: [UInt16] = [
            0, 1, 2, 2, 3, 0, // Front face
            1, 5, 6, 6, 2, 1, // Right face
            3, 2, 6, 6, 7, 3, // Top face
            4, 5, 1, 1, 0, 4, // Bottom face
            4, 0, 3, 3, 7, 4, // Left face
            7, 6, 5, 5, 4, 7  // Back face
        ]
        indexBuffer = device.makeBuffer(
            bytes: indexData,
            length: indexData.count * MemoryLayout<UInt16>.stride,
            options: [])
    }
    
    private func registerShaders() -> (MTLFunction?, MTLFunction?)
    {
        let library = device.makeDefaultLibrary()
        let vertexShader = library?.makeFunction(name: "vertex_shader")
        let fragmentShader = library?.makeFunction(name: "fragment_shader")
        
        return (vertexShader, fragmentShader)
    }
    
    private func updateUniformState()
    {
        let scaled = Matrix.scalingMatrix(0.5)
        rotation += 1/100 * Float.pi / 4
        
        let rotatedY = Matrix.rotationMatrix(rotation, SIMD3<Float>(0, 1, 0))
        let rotatedX = Matrix.rotationMatrix(Float.pi/4, SIMD3<Float>(1, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
        
        let cameraPosition = vector_float3(0, 0, -3)
        let viewMatrix = Matrix.translationMatrix(cameraPosition)
        let projMatrix = Matrix.projectionMatrix(near: 0, far: 10, aspect: 1, fovy: 1)
        
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.stride)
    }
}

extension Renderer : MTKViewDelegate
{
    // `metalKitView` will call this function whenever it wants new content to be rendered
    func draw(in view: MTKView)
    {
        gpuLock.wait()
        
        updateUniformState()
        
        // Get an available command buffer:
        // An `MTLCommandBuffer` represents the entire set of information the GPU
        // needs to execute this pipeline: it contains the pipeline info itself,
        // as well as vertex data and drawing commands that will be fed into the
        // pipeline by the GPU.
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // Get the default MTLRenderPassDescriptor from the MTKView argument:
        // An `MTLRenderPassDescriptor` is used to configure the interface of the pipeline
        // but not the interior of the pipeline.
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        // Change default settings. For example, we change the clear colour from black to red.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        // Compile `renderPassDescriptor` to a MTLRenderCommandEncoder:
        // An `MTLRenderCommandEncoder` is used to prepare the vertex data and drawing
        // commands that will be fed into the pipeline.
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        // Setup render commands to encode
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        renderEncoder.setRenderPipelineState(pipelineState) // What render pipeline to use
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0) // Vertex buffer to use
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)// Uniform buffer
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride,
            indexType: MTLIndexType.uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)
        
        // Finalize the encoding of drawing commands
        renderEncoder.endEncoding()
        
        // Tell Metal to send the rendering result to the MTKView when renderering completes
        commandBuffer.present(view.currentDrawable!)
        
        commandBuffer.addCompletedHandler { _ in
            self.gpuLock.signal()
        }
        
        // Send the encoded command buffer to the GPU, which is stored in the command queue
        commandBuffer.commit()
    }
    
    // `metalKitView` will call this function whenever the size of the view changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
