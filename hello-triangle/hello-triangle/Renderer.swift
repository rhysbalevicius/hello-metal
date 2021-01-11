//
//  Renderer.swift
//  hello-triangle
//
//  Created by Rhys Balevicius on 2021-01-10.
//

import Metal
import MetalKit

class Renderer : NSObject
{
    // MARK: - Private properties
    private let metalKitView           : MTKView
    private let device                 : MTLDevice
    private let commandQueue           : MTLCommandQueue
    private var pipelineState          : MTLRenderPipelineState!
    private var vertexBuffer           : MTLBuffer!
    private var fragmentUniformsBuffer : MTLBuffer!
    
    private var lastRenderTime : CFTimeInterval?
    private var currentTime    : Double = 0
    private let gpuLock = DispatchSemaphore(value: 1)
    
    // MARK: - Lifecycle
    init?(metalKitView: MTKView)
    {
        self.metalKitView = metalKitView
        
        // Represents the actual GPU
        self.device = metalKitView.device!
        
        // An `MTLCommandQueue` keeps track of many `MTLCommandBuffer` objects
        // that are waiting to be executed.
        self.commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        // Create the render pipeline
        do {
            pipelineState = try buildRenderPipelineWith(device: device, metalKitView: metalKitView)
        } catch {
            print("Unable to compile render pipeline state: \(error)")
            return nil
        }
        
        // Create our vertex data
        let vertices = [
            Vertex(colour: [1, 0, 0, 1], position: [-1, -1]),
            Vertex(colour: [0, 1, 0, 1], position: [0, 1]),
            Vertex(colour: [0, 0, 1, 1], position: [1, -1])
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        
        // Create our uniform buffer and fill it with an initial brightness of 1.0
        var initialFragmentUniforms = FragmentUniforms(brightness: 1.0)
        fragmentUniformsBuffer = device.makeBuffer(bytes: &initialFragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])!
        
    }
    
    // MARK: - Private functions
    private func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState
    {
        // Create a new pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        // Setup the shaders in the pipeline
        let library = device.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_shader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_shader")
        
        // Setup the output pixel format to match the pixel format of the metal kit view
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        // Compile the configure pipeline descriptor to a pipeline state object
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private func updateState(dt: CFTimeInterval)
    {
        let pointer = fragmentUniformsBuffer.contents().bindMemory(to: FragmentUniforms.self, capacity: 1)
        pointer.pointee.brightness = Float(0.5 * cos(currentTime) + 0.5)
        
        currentTime += dt
    }
}

extension Renderer : MTKViewDelegate
{
    // `metalKitView` will call this function whenever the size of the view changes
    func draw(in view: MTKView)
    {
        gpuLock.wait()
        
        // Compute dt
        let systemTime = CACurrentMediaTime()
        let timeDifference = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        
        // Store the system time on this call
        lastRenderTime = systemTime
        
        // Update the state w.r.t time
         updateState(dt: timeDifference)
        
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
        renderEncoder.setRenderPipelineState(pipelineState) // What render pipeline to use
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0) // Vertex buffer to use
        renderEncoder.setFragmentBuffer(fragmentUniformsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3) // What to draw
        
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
    
    // `metalKitView` will call this function whenever it wants new content to be rendered
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        
    }
}
