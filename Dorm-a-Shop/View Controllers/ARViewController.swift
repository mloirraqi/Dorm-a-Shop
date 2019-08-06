//
//  ARViewController.swift
//  Dorm-a-Shop
//
//  Created by addisonz on 8/2/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

import UIKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    private var hud :MBProgressHUD!
    var currentAngleY: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hud = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        self.hud.label.text = "Detecting Plane..."
        
        self.sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView () {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration)
    }
    
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGesture.delegate = self
        self.sceneView.addGestureRecognizer(panGesture)
    }
    
    @objc func pinched(recognizer :UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            guard let sceneView = recognizer.view as? ARSCNView else {
                return
            }

            let touch = recognizer.location(in: sceneView)
            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
            
            if let hitTest = hitTestResults.first {
                let chairNode = hitTest.node
    
                let pinchScaleX = Float(recognizer.scale) * (chairNode.parent?.scale.x ?? chairNode.scale.x)
                let pinchScaleY = Float(recognizer.scale) * (chairNode.parent?.scale.x ?? chairNode.scale.y)
                let pinchScaleZ = Float(recognizer.scale) * (chairNode.parent?.scale.x ?? chairNode.scale.z)

                (chairNode.parent ?? chairNode).scale = SCNVector3(pinchScaleX,pinchScaleY,pinchScaleZ)
                recognizer.scale = 1
            }
        }
    }
    
    @objc func tapped(recognizer :UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else {
            return
        }
        
        let touch = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touch, types: .existingPlane)
        
        if let hitTest = hitTestResults.first {
            let chairScene = SCNScene(named: "chair.scn")!
            guard let chairNode = chairScene.rootNode.childNode(withName: "chair", recursively: true) else {
                return
            }
            
            chairNode.position = SCNVector3(hitTest.worldTransform.columns.3.x,hitTest.worldTransform.columns.3.y,hitTest.worldTransform.columns.3.z)
            self.sceneView.scene.rootNode.addChildNode(chairNode)
        }
    }
    
    @objc func didPan(gesture: UIPanGestureRecognizer) {
        guard let sceneView = gesture.view as? ARSCNView else {
            return
        }

        let touch = gesture.location(in: sceneView)
        let hitTestResults = self.sceneView.hitTest(touch, options: nil)

        if let hitTest = hitTestResults.first {
            let chairNode = hitTest.node

            let translation = gesture.translation(in: gesture.view)
            var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0

            newAngleY += currentAngleY
            (chairNode.parent ?? chairNode).eulerAngles.y = newAngleY

            if gesture.state == .ended{
                currentAngleY = newAngleY
            }
            
            let hitResult = self.sceneView.hitTest(touch, types: .existingPlane)
            if !hitResult.isEmpty{
                guard let hitResult = hitResult.last else { return }
                (chairNode.parent ?? chairNode).position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
            }
        }
        
       
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.hud.label.text = "Plane Detected"
            self.hud.hide(animated: true, afterDelay: 1.0)
        }
 
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
    
    @IBAction func reset(_ sender: Any) {
        self.restartSession()
    }

    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (chairNode, _) in
            chairNode.removeFromParentNode()
        }
        self.setUpSceneView()
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}
