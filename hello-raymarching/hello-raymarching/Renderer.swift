//
//  Renderer.swift
//  hello-raymarching
//
//  Created by Rhys Balevicius.
//

import MetalKit

struct Uniforms
{
    var time: Float
}

class Renderer : NSObject
{
    // MARK: - Private properties
    private var metalKitView           : MTKView!
    private var device                 : MTLDevice!
    private var commandQueue           : MTLCommandQueue!
    private var pipelineState          : MTLComputePipelineState!
    private let gpuLock = DispatchSemaphore(value: 1)
    
    private var uniformBuffer : MTLBuffer!
    private var currentTime   : Float = 0
    
    // MARK: - Lifecycle
    init?(metalKitView: MTKView)
    {
        super.init()
        
        self.metalKitView = metalKitView
        self.metalKitView.framebufferOnly = false
        self.device = metalKitView.device!
        self.commandQueue = device.makeCommandQueue()!
        
        // Create the render pipeline
        do {
            pipelineState = try buildComputePipelineWith(device: device)
        } catch {
            print("Unable to compile compute pipeline state: \(error)")
            return nil
        }
    }
    
    // MARK: - Private functions
    private func buildComputePipelineWith(device: MTLDevice) throws -> MTLComputePipelineState
    {
        let library = device.makeDefaultLibrary()
        let computeShader = library?.makeFunction(name: "compute")
        
        // Create the time uniform buffer
        var uniforms = Uniforms(time: currentTime)
        uniformBuffer = device.makeBuffer(
            bytes: &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            options: [])
        
        // Try to compile the configure pipeline descriptor to a pipeline state object
        return try device.makeComputePipelineState(function: computeShader!)
    }
    
    private func updateUniforms()
    {
        currentTime += 0.01
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(time: currentTime)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.stride)
    }
}

extension Renderer : MTKViewDelegate
{
    // `metalKitView` will call this function whenever it wants new content to be rendered
    func draw(in view: MTKView)
    {
        gpuLock.wait()

        updateUniforms()
        
        guard let texture = view.currentDrawable?.texture else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
       
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
        commandEncoder.setTexture(texture, index: 0)
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(
            texture.width / threadGroupCount.width,
            texture.height / threadGroupCount.height, 1)
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.addCompletedHandler { _ in self.gpuLock.signal() }
        commandBuffer.commit()
        
        
    }
    
    // `metalKitView` will call this function whenever the size of the view changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
