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
    
    // button setup
    let buttonInner = SCNNode()
    let buttonOuter = SCNNode()
    let buttonOuterParent = SCNNode()
    var buttonAdded = false
    let buttonInnerHeight = 0.006
    
    override func viewWillAppear(_ animated: Bool) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // taking out origin/feature points for now but we will need some kind of UI
        // self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.session.run(configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.delegate = self
        self.registerGestureRecognizers()
        self.setUpButton()
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

    // tap gesture recognizer function for adding the button (hit test against plane)
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTestButton = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        // only add a button if the plane hit test was successful and there is no existing button
        if !hitTestButton.isEmpty && !self.buttonAdded {
            self.addButton(hitTestResult: hitTestButton.first!)
        }
    }
    
    // tap gesture function for pressing the button (excludes plane from hit test)
    // possible that this could be combined with tapped() but wasn't working before
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self.sceneView)
        var hitTestPressOptions = [SCNHitTestOption:Any]()
        hitTestPressOptions[SCNHitTestOption.boundingBoxOnly] = true
        let hitPressResults: [SCNHitTestResult] = self.sceneView.hitTest(location, options: hitTestPressOptions)
        
        // only press the button if the hit test was successful and button is not already being animated
            if !hitPressResults.isEmpty && self.buttonInner.animationKeys.isEmpty {
                self.pressButton(node: self.buttonInner)
        }
    }
    
    // get geometry of button set up before placing it
    func setUpButton() {
        // inner, pressable part of button
        let buttonInnerRadius = 0.05
        self.buttonInner.geometry = SCNCylinder(radius: CGFloat(buttonInnerRadius), height: CGFloat(self.buttonInnerHeight))
        self.buttonInner.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        self.buttonInner.geometry?.firstMaterial?.specular.contents = UIColor.cyan
        
        // outer, stationary part of button - child of buttonOuterParent so that it is positioned w.r.t. buttonInner
        // but does not move with buttonInner
        // could put some safeguards on the geometry math, but we'll switch this out to be a nicer model anyway
        let buttonOuterIRadius = buttonInnerRadius
        let buttonOuterORadius = 1.2 * buttonOuterIRadius
        let buttonOuterHeight = 0.0125
        self.buttonOuter.geometry = SCNTube(innerRadius: CGFloat(buttonOuterIRadius), outerRadius: CGFloat(buttonOuterORadius), height: CGFloat(buttonOuterHeight))
        self.buttonOuter.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        self.buttonOuter.geometry?.firstMaterial?.specular.contents = UIColor.white
        self.buttonOuter.position = SCNVector3(0, -0.5 * (self.buttonInnerHeight + buttonOuterHeight),0)
        self.buttonOuterParent.addChildNode(self.buttonOuter)
        
        // flat disk to cover the bottom of the button - also a child of buttonOuterParent so that it doesn't move
        let buttonBottomHeight = 0.001
        let buttonBottom = SCNNode(geometry: SCNCylinder(radius: CGFloat(buttonOuterORadius), height: CGFloat(buttonBottomHeight)))
        buttonBottom.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        buttonBottom.geometry?.firstMaterial?.specular.contents = UIColor.white
        buttonBottom.position = SCNVector3(0, -0.5 * (self.buttonInnerHeight + buttonBottomHeight) - buttonOuterHeight,0)
        self.buttonOuterParent.addChildNode(buttonBottom)
    }
    
    // get the location of the tap and place buttonInner and buttonOuterParent in the scene
    func addButton(hitTestResult: ARHitTestResult) {
        self.buttonAdded = true
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        self.buttonInner.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.buttonOuterParent.position = self.buttonInner.position
        self.sceneView.scene.rootNode.addChildNode(self.buttonInner)
        self.sceneView.scene.rootNode.addChildNode(self.buttonOuterParent)
        
    }

    // animate buttonInner when pressed
    func pressButton(node: SCNNode) {
        let press = CABasicAnimation(keyPath: "position")
        press.fromValue = node.presentation.position
        press.toValue = SCNVector3(node.presentation.position.x, node.presentation.position.y - Float(0.5 * self.buttonInnerHeight), node.presentation.position.z)
        press.autoreverses = true
        press.duration = 0.3
        node.addAnimation(press, forKey: "position")
    }

}

