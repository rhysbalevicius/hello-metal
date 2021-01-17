//
//  ViewController.swift
//  hello-scnprogram
//

import UIKit
import ARKit
import SceneKit

extension ViewController: ARSCNViewDelegate {}

class ViewController: UIViewController {
    public var sceneView: ARSCNView!
    public var node : SCNNode!
    public var time: Float = 0
    public var viewSize : CGSize!

    override internal func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds, options: [
            SCNView.Option.preferredRenderingAPI.rawValue : SCNRenderingAPI.metal
        ])
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        view.addSubview(sceneView)
        
        viewSize = sceneView.bounds.size
        addNode()
        
        // On tap, replace our nodes material with our custom SCNProgram
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(addSCNProgramToNode))
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.isUserInteractionEnabled = true
    }
    
    override internal func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        instantiateARSession()
    }
    
    override internal func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    private func instantiateARSession()
    {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func addNode()
    {
        let geometry = SCNSphere(radius: 0.5)

//        let geometry = SCNPlane(width: 1, height: 1)
//        geometry.widthSegmentCount = 100
//        geometry.heightSegmentCount = 100
        
        geometry.firstMaterial?.diffuse.contents = UIColor.red // Initial material, to verify where the node is
        
        // Position and add the node to the scene
        node = SCNNode(geometry: geometry)
        node.position = SCNVector3(0, 0, -1)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    @objc private func addSCNProgramToNode()
    {
        if let geometry = node.geometry {
            // Create an SCNProgram to replace the sphere's material
            let program = SCNProgram()
            program.vertexFunctionName = "vertexShader"
            program.fragmentFunctionName = "fragmentShader"
            
            if let material = geometry.firstMaterial {
                material.program = program
                
                if let contents = sceneView.scene.background.contents {
                    material.setValue(SCNMaterialProperty(contents: contents), forKey: "texture")
                    material.setValue(Float(0), forKey: "u_time")
                    updateDisplayTranform()
                    
                    let test = SCNNode()
                    let geo = SCNTorus()
                    test.geometry = geo
                    
                    material.setValue(test, forKey: "u_test")
                }
            }
            
            geometry.firstMaterial?.program = program
            
            let timer = CADisplayLink(target: self, selector: #selector(updateUniforms))
            timer.preferredFramesPerSecond = 60
            timer.add(to: .current, forMode: .common)
        }
    }
    
    // Continuously update our uniforms over time
    @objc private func updateUniforms()
    {
        time += 1/60
        node.geometry?.firstMaterial?.setValue(time, forKey: "u_time")
        updateDisplayTranform()
    }
    
    private func updateDisplayTranform()
    {
        guard let frame = sceneView.session.currentFrame else { return }
        let affineTransform = frame.displayTransform(for: .portrait, viewportSize: sceneView.bounds.size)
        let transform = SCNMatrix4(affineTransform)
        
        node.geometry?.firstMaterial?.setValue(SCNMatrix4Invert(transform), forKey: "u_displayTransform")
    }
}
