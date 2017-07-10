//
//  PartThreeView.swift
//  ARPartThree
//
//  Created by joltdev on 7/10/17.
//  Copyright © 2017 joltdev. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class PartThreeView: UIViewController, ARSCNViewDelegate {
    
    var sceneView: ARSCNView!
    
    let rawValue: Int = 4
    let bottom = CollisionCategory(rawValue: 1 << 0)
    let cube = CollisionCategory(rawValue: 1 << 1)
    
    var planes = [AnyHashable: Any]()
    var boxes = [Any]()
    
    override func viewDidLoad() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func setupScene() {
        sceneView = ARSCNView(frame: self.view.frame)
        view.addSubview(sceneView)
        sceneView.delegate = self
        
        planes = [AnyHashable: Any]()
        boxes = [Any]()
        
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        let myScene = SCNScene()
        sceneView.scene = myScene
        
        let bottomPlane = SCNBox(width: 1000, height: 0.5, length: 1000, chamferRadius: 0)
        let bottomMaterial = SCNMaterial()
        bottomMaterial.diffuse.contents = UIColor(white: CGFloat(1), alpha: CGFloat(0.0))
        bottomPlane.materials = [bottomMaterial]
        
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3Make(0, -10, 0)
        
        bottomNode.physicsBody?.categoryBitMask = CollisionCategory.bottom.rawValue
        bottomNode.physicsBody?.categoryBitMask = CollisionCategory.cube.rawValue
        
        sceneView.scene.rootNode.addChildNode(bottomNode)
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func setupSession() {
        let config = ARWorldTrackingSessionConfiguration()
        config.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
        
        sceneView.session.run(config)
    }
    
    func setupRecgonizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(from:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let explosionGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleHold(from:)))
        explosionGestureRecognizer.minimumPressDuration = 1
        sceneView.addGestureRecognizer(explosionGestureRecognizer)
        
        let hidePlanesGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleHidePlane(from:)))
        hidePlanesGestureRecognizer.minimumPressDuration = 1
        hidePlanesGestureRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(hidePlanesGestureRecognizer)
    }
    
    @objc func handleTap(from recognizer: UITapGestureRecognizer) {
        
        let tapPoint: CGPoint = recognizer.location(in: sceneView)
        let result : [ARHitTestResult] = sceneView.hitTest(tapPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        if result.count == 0 {
            return
        }
        
        let hitResult : ARHitTestResult? = result.first
        insertGeometry(hitResult)
    }
    
    @objc func handleHidePlane(from recognizer: UILongPressGestureRecognizer) {
        
        if recognizer.state != .began {
            return
        }
        
        for planeId in planes {
            let thisThing = ARWorldTrackingSessionConfiguration()
            thisThing.planeDetection = []
        }
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = []
        
        sceneView.session.run(configuration)
        
    }
    
    @objc func handleHold(from recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .began {
            return
        }
        
        let holdPoint: CGPoint = recognizer.location(in: sceneView)
        let result : [ARHitTestResult] = sceneView.hitTest(tapPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        if result.count == 0 {
            return
        }
        
        let hitresult: ARHitTestResult? = result.first
        DispatchQueue.main.async(execute: {() -> Void in
            self.explode(hitresult!)
        })
    }
    
    func explode(_ hitResult: ARHitTestResult) {
        
        let explosionYOffset: Float = 0.1
        let position = SCNVector3Make(Float(hitResult.worldTransform.columns.3.x), Float(hitResult.worldTransform.columns.3.y), Float(hitResult.worldTransform.columns.3.z))
        
        for cubeNode in boxes {
            var cubeAny = cubeNode as AnyObject
            var worldPosition = cubeAny.worldPosition!
            var distance: SCNVector3 = SCNVector3Make(worldPosition.x - position.x, worldPosition.y - position.y, worldPosition.z - position.z)
            
            let len: Float = sqrt(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            
            let maxDistance: Float = 2
            var scale: Float = max(0, (maxDistance - len))
            
            scale = scale * scale * 2
            
            distance.x = distance.x / len * scale
            distance.y = distance.y / len * scale
            distance.z = distance.z / len * scale
            
            (cubeNode as! SCNNode).physicsBody?.applyForce(distance, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
        }
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    
    
}
