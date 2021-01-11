//
//  ViewController.swift
//  hello-triangle
//
//  Created by Rhys Balevicius on 2021-01-10.
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

        metalKitView = MTKView()
        metalKitView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
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
        view.window?.title = "Hello, Triangle"
    }
}

