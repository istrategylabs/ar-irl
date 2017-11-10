//
//  ViewController.swift
//  AR-irl_V2
//
//  Created by Adam Hughes on 11/2/17.
//  Copyright © 2017 Adam Hughes. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var TaptoReveal: UILabel!
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var buttonAdded: Bool = false
    var castsShadows: Bool = true
    var isOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configuration.planeDetection = .horizontal
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
//        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        insertSpotLight(position: SCNVector3(0,3.0,1.0))
    
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    

    private func insertSpotLight (position: SCNVector3) {

        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.spotInnerAngle = 45
        spotLight.spotOuterAngle = 45
        spotLight.automaticallyAdjustsShadowProjection = true
        spotLight.shadowRadius = 50

        let spotNode = SCNNode()
        spotNode.name = "SpotNode"
        spotNode.light = spotLight
        spotNode.position = position

        spotNode.eulerAngles = SCNVector3(-80.degreesToRadians, 0, 0.2)
        self.sceneView.scene.rootNode.addChildNode(spotNode)

        }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        // if hit test is not (!) empty add room
        if !hitTestResult.isEmpty {
            self.addButton(hitTestResult: hitTestResult.first!)
        } else{
            //
        }
    }
    
    func addButton(hitTestResult: ARHitTestResult) {
        if buttonAdded == false {
            let buttonScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")
            let buttonNode = buttonScene!.rootNode.childNode(withName: "Top", recursively: true)
            let transform = hitTestResult.worldTransform
            let planeXposition = transform.columns.3.x
            let planeYposition = transform.columns.3.y
            let planeZposition = transform.columns.3.z
            buttonNode?.position = SCNVector3(planeXposition, planeYposition, planeZposition)
            self.sceneView.scene.rootNode.addChildNode(buttonNode!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.buttonAdded = true
            }
        }
    }
    
    

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard anchor is ARPlaneAnchor else {return}
        
//
//        if planeDetected.isHidden {
//            planeDetected.alpha = 1.0
//            UIView.animate(withDuration: 0.5) {
//                self.planeDetected.alpha = 0.0
//            }
//        } else {
//            UIView.animate(withDuration: 0.5) {
//                self.planeDetected.alpha = 1.0
//            }
//
//        }

                                    //need to make sure below happens on the main thread
                                    DispatchQueue.main.async {
                                        // unhide detected plane
                                        self.planeDetected.isHidden = false
                                        self.sceneView.debugOptions = []
                                        // make label go away after 2 more seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            self.planeDetected.isHidden = true
                                            self.TaptoReveal.isHidden = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                            self.TaptoReveal.isHidden = true
                                        }
                                    }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let estimate = self.sceneView.session.currentFrame?.lightEstimate
        if estimate == nil {
            return
        }
//        guard let buttonNode = sceneView.scene.rootNode.childNode(withName: "Top", recursively: true) else {
//            return
//        }
        

        let spotNode = self.sceneView.scene.rootNode.childNode(withName: "SpotNode", recursively: true)
        spotNode?.light?.intensity = ((estimate?.ambientIntensity)!)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func reset(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "Top" {
            node.removeFromParentNode()
            }
        }
        self.buttonAdded = false
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

