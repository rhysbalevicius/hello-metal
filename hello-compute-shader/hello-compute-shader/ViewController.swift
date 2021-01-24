//
//  ViewController.swift
//  hello-compute-shader
//
//  Created by Rhys Balevicius.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController
{
    // MARK: - Private properties
    private var metalKitView : MTKView!
    private var renderer     : Renderer!

    // MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.frame = CGRect(x: 0, y: 0, width: 500, height: 500)

        metalKitView = MTKView()
        metalKitView.frame = CGRect(x: 0, y: 0, width: view.frame.height, height: view.frame.height)
        view.addSubview(metalKitView)
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        metalKitView.device = device
        
        guard let renderer = Renderer(metalKitView: metalKitView) else {
            print("Renderer failed to initialize")
            return
        }
        self.renderer = renderer
        metalKitView.delegate = renderer
    }

    override func viewDidAppear() {
        view.window?.title = "Hello, Compute Shader"
    }
}

