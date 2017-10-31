//
//  ViewController.swift
//  ar-irl
//
//  Created by Trish O'Connor on 10/27/17.
//  Copyright © 2017 Trish O'Connor. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let button = SCNNode()
    let nodeName = "button"
    var buttonAdded = false
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.delegate = self
        self.registerGestureRecognizers()
        self.setUpButton()
        let scene  = SCNScene()
        self.sceneView.scene = scene
        self.sceneView.autoenablesDefaultLighting = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTestButton = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTestButton.isEmpty && !self.buttonAdded {
            print("place button")
            self.addButton(hitTestResult: hitTestButton.first!)
        }
//        let hitTestUnlock = sceneView.hitTest(tapLocation, options: [:])
//        if !hitTestUnlock.isEmpty && buttonAdded {
//            print("press button")
//            let node = hitTestUnlock.first!.node
//            if node.animationKeys.isEmpty{
//                pressButton(node: node)
//            }
//        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self.sceneView)
        var hitTestPressOptions = [SCNHitTestOption:Any]()
        hitTestPressOptions[SCNHitTestOption.boundingBoxOnly] = true
        let hitPressResults: [SCNHitTestResult] = self.sceneView.hitTest(location, options: hitTestPressOptions)
        if self.buttonAdded {
            if let hit = hitPressResults.first {
                if let node = getParent(hit.node) {
                    self.pressButton(node: node)
                }
            }
        }
//        if !hitPressResults.isEmpty && self.buttonAdded {
//            print(hitPressResults.first!.node.geometry!)
//            if hitPressResults.first?.node.geometry! ==  self.button.geometry! {
//                if self.button.animationKeys.isEmpty {
//                    print("press button")
//                    self.pressButton(node: self.button)
//                }
//            }
//        }
    }
    
    func getParent(_ nodeFound:SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == self.nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
    func setUpButton() {
        self.button.geometry = SCNBox(width: 0.1, height: 0.05, length: 0.1, chamferRadius: 0)
        self.button.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        self.button.geometry?.firstMaterial?.specular.contents = UIColor.cyan
        
    
    }
    
    func addButton(hitTestResult: ARHitTestResult) {
        self.buttonAdded = true
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        self.button.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.sceneView.scene.rootNode.addChildNode(self.button)
        
    }

    
    func pressButton(node: SCNNode) {
//        let press = CABasicAnimation(keyPath: "position")
        let press = CABasicAnimation(keyPath: "transform.scale.y")
        press.fromValue = 1
        press.toValue = 0.5
//        press.fromValue = node.presentation.position
//        press.toValue = SCNVector3(node.presentation.position.x, node.presentation.position.y - 0.03, node.presentation.position.z)
        press.autoreverses = true
        press.duration = 0.5
        node.addAnimation(press, forKey: "position")
    }

}

