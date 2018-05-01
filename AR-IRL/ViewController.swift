//
//  ViewController.swift
//  AR-irl_V2
//
//  Created by Adam Hughes on 11/2/17.
//  Copyright © 2017 Adam Hughes. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    var buttonScene = SCNScene()
    var buttonTopNode = SCNNode()
    var buttonBaseNode = SCNNode()
    
    var buttonAdded: Bool = false
    var QRReader: Bool = true
    var detectedCenterAnchor: ARAnchor?
    var processing = false
    var created = false
    let QR1 = "picasso"
    
    // Photon setup
    var photon: ParticleDevice?
    var deviceFound: Bool = false
    
    // code logic
    let code = "redgreenorangeblue"
    var entry = ""
    var cover = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        insertSpotLight(position: SCNVector3(0,3.0,1.0))
        
        var imagesNames = ["Comp 1_00", "Comp 1_01", "Comp 1_02", "Comp 1_03", "Comp 1_04", "Comp 1_05", "Comp 1_06","Comp 1_07", "Comp 1_08", "Comp 1_09", "Comp 1_10", "Comp 1_11", "Comp 1_12", "Comp 1_13", "Comp 1_14", "Comp 1_15", "Comp 1_16", "Comp 1_17", "Comp 1_18", "Comp 1_19"]
        
        if QRReader == true {
            var images = [UIImage]()
            for i in 0..<imagesNames.count {
                images.append(UIImage(named: imagesNames[i])!)
            }
            imageView.animationImages = images
            imageView.startAnimating()
        } else {
            imageView.stopAnimating()
            imageView.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // add Spotlight
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
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // this could probably change to an if let
        let estimate = self.sceneView.session.currentFrame?.lightEstimate
        if estimate == nil {
            return
        }
        
        let spotNode = self.sceneView.scene.rootNode.childNode(withName: "SpotNode", recursively: true)
        spotNode?.light?.intensity = ((estimate?.ambientIntensity)!)
    }
    
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // don't keep looking once it's placed and remove white square
        if self.buttonAdded {
            self.imageView.stopAnimating()
            self.imageView.isHidden = true
            return
        }
        
        // Only run one Vision request at a time
        if self.processing {
            return
        }
        
        self.processing = true

        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest { (request, error) in

            // Get the first result out of the results, if there are any
            if let results = request.results, let result = results.first as? VNBarcodeObservation {
                print("<qr>")
                print(result.barcodeDescriptor!)
                print(result.payloadStringValue ?? "nope")
                print(result.symbology._rawValue)
                print("</qr>")
                // Get the bounding box for the bar code and find the center
                var rect = result.boundingBox

                // Flip coordinates
                rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))

                // Get center
                let center = CGPoint(x: rect.midX, y: rect.midY)

                // Go back to the main thread
                DispatchQueue.main.async {
                    if result.payloadStringValue ?? "nope" == self.QR1 {
                        //picasso
                        // Perform a hit test on the ARFrame to find a surface
                        let hitTestCenterResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
                        // If we have a result, process it
                        if let hitTestCenterResult = hitTestCenterResults.first {
                            
                            // If we already have an anchor, update the position of the attached node
                            if let detectedCenterAnchor = self.detectedCenterAnchor,
                                let node = self.sceneView.node(for: detectedCenterAnchor) {
                                node.transform = SCNMatrix4(hitTestCenterResult.worldTransform)
                                print("<center>")
                                print(node.rotation)
                                print(node.orientation)
                                print(node.position)
                                print(node.eulerAngles)
                                print(node.transform)
                                print("</center>")
                            } else {
                                // Create an anchor. The node will be created in delegate methods
                                self.detectedCenterAnchor = ARAnchor(transform: hitTestCenterResult.worldTransform)
                                self.sceneView.session.add(anchor: self.detectedCenterAnchor!)
                            }
                        }
                    }
                    // Set processing flag off
                    self.processing = false
                }
            } else {
                // Set processing flag off
                self.processing = false
            }
        }

        // Process the request in the background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Set it to recognize QR code only
                request.symbologies = [.QR]
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                // Process the request
                try imageRequestHandler.perform([request])
            } catch {
                
            }
        }
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // If this is our anchor, create a node
        if self.detectedCenterAnchor?.identifier == anchor.identifier {
//            let wrapperNode = createButton(name: "original", anchor: anchor)
            let wrapperNode = createKeypad(anchor: anchor)
            self.buttonAdded = true
            QRReader = false

            // for multiple, will probably return parent of all the wrappers
            return wrapperNode
        }
        return nil
    }

    func createKeypad(anchor: ARAnchor) -> SCNNode {
        let red = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        red.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        red.position = SCNVector3(0.0125, 0, 0.0125)
        red.name = "red"

        let green = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        green.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        green.position = SCNVector3(0.0125, 0, -0.0125)
        green.name = "green"

        let blue = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        blue.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        blue.position = SCNVector3(-0.0125, 0, -0.0125)
        blue.name = "blue"

        let orange = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        orange.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        orange.position = SCNVector3(-0.0125, 0, 0.0125)
        orange.name = "orange"

        let clear = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        clear.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        clear.position = SCNVector3(-0.0125, 0, 0.05)
        clear.name = "clear"

        let enter = SCNNode(geometry: SCNBox(width: 0.02, height: 0.01, length: 0.02, chamferRadius: 0))
        enter.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        enter.position = SCNVector3(0.0125, 0, 0.05)
        enter.name = "enter"
        
        self.cover.geometry = SCNPlane(width: 0.5, height: 0.5)
        self.cover.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        self.cover.position = SCNVector3(0, 0, 0)
        self.cover.eulerAngles = SCNVector3(-90.degreesToRadians, 0, 0)
        self.cover.name = "ignore"
        

        let wrapperNode = SCNNode()
        wrapperNode.addChildNode(red)
        wrapperNode.addChildNode(green)
        wrapperNode.addChildNode(blue)
        wrapperNode.addChildNode(orange)
        wrapperNode.addChildNode(clear)
        wrapperNode.addChildNode(enter)
        wrapperNode.addChildNode(self.cover)

        wrapperNode.transform = SCNMatrix4(anchor.transform)

        return wrapperNode
    }

    func createButton(name: String, anchor:ARAnchor) -> SCNNode {
        // Button Top Node
        self.buttonScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")!
        self.buttonTopNode = (self.buttonScene.rootNode.childNode(withName: "Top", recursively: true))!
        self.buttonTopNode.position = SCNVector3(0,0,0)
        
        // Button Bottom Node
        self.buttonBaseNode = (self.buttonScene.rootNode.childNode(withName: "Base", recursively: true))!
        self.buttonBaseNode.position = SCNVector3(0,0,0)
        
        let wrapperNode = SCNNode()
        wrapperNode.addChildNode(buttonTopNode)
        wrapperNode.addChildNode(buttonBaseNode)
        
        //wrapper may not be necessary w/o scn but use for now
        wrapperNode.transform = SCNMatrix4(anchor.transform)
        
        return wrapperNode
    }

//        @objc func tapped(sender: UITapGestureRecognizer) {
//            guard let sceneView = sender.view as? ARSCNView else {return}
//            let touchLocation = sender.location(in: sceneView)
//            let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
//            // if hit test is not (!) empty add room
//            if !hitTestResult.isEmpty {
//                self.pushButton(hitTestResult: hitTestResult.first!)
//            } else{
//                //
//            }
//        }
    
    // tap gesture function for pressing the button (excludes plane from hit test)
    // possible that this could be combined with tapped() but wasn't working before
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self.sceneView)
        var hitTestPressOptions = [SCNHitTestOption:Any]()
        hitTestPressOptions[SCNHitTestOption.boundingBoxOnly] = true
        let hitPressResults: [SCNHitTestResult] = self.sceneView.hitTest(location, options: hitTestPressOptions)


        // only press the button if the hit test was successful and button is not already being animated
        if !hitPressResults.isEmpty && buttonTopNode.animationKeys.isEmpty {
            let nodeTouched = hitPressResults[0].node
            if (nodeTouched.name == "ignore") {
                return
            }
            
            self.pressButton(node: nodeTouched)
            print(nodeTouched.name ?? "none")
            if (nodeTouched.name == "clear") {
                print("clearing")
                clearCode()
            } else if (nodeTouched.name == "enter") {
                print("entering")
                checkCode()
            } else {
                self.entry.append(nodeTouched.name ?? "")
                print("adding to entry")
                print("entry: " + self.entry)
            }
//            self.pressButton(node: buttonTopNode)
        }
    }

    func pressButton(node: SCNNode) {
        let press = CABasicAnimation(keyPath: "position")
            press.fromValue = node.presentation.position
            press.toValue = SCNVector3(node.presentation.position.x, node.presentation.position.y - Float(0.25.inchesToMeters), node.presentation.position.z)
            press.autoreverses = true
            press.duration = 0.2
            node.addAnimation(press, forKey: "position")
    }

    func switchLight() {
        let funcArgs = [""]
        self.photon?.callFunction("lights", withArguments: funcArgs) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("switchLights particle function called")
            }
            else{
                print("switchLights particle function error")
            }
        }
    }

    func turnOnLight() {
        let funcArgs = [""]
        self.photon?.callFunction("lightsOn", withArguments: funcArgs) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("lightsOn particle function called")
            }
            else{
                print("lightsOn particle function error")
            }
        }
    }

    func turnOffLight() {
        let funcArgs = [""]
        self.photon?.callFunction("lightsOff", withArguments: funcArgs) { (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("lightsOff particle function called")
            }
            else{
                print("lightsOff particle function error")
            }
        }
    }

    @IBAction func connectToParticleButton(_ sender: Any) {
        let setupController = ParticleSetupMainController()
        self.present(setupController!, animated: true, completion: nil)
    }

    @IBAction func findDeviceButton(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.deviceFound = false
            ParticleCloud.sharedInstance().getDevices { (devices:[ParticleDevice]?, error:Error?) -> Void in
                if let _ = error {
                    print("Check your internet connectivity")
                }
                else {
                    if let d = devices {
                        for device in d {
                            if device.name == "ar-irl-photon" {
                                self.photon = device
                                self.deviceFound = true
                                print("found device")
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func reset(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        // need to put a safeguard in here in case that anchor doesn't exist yet (restart pressed before 1st button placed)
        self.sceneView.session.remove(anchor: detectedCenterAnchor!)
        DispatchQueue.main.async {
            self.imageView.startAnimating()
            self.imageView.isHidden = false
            self.buttonAdded = false
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkCode() {
        if self.entry == self.code {
            print("right")
            // open box
            // hide keypad
            turnOnLight()
            clearCode()
        } else {
            print ("wrong")
            // possibly show red lights or something
            clearCode()
        }
    }

    func clearCode() {
        turnOffLight()
        entry = ""
    }
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

extension Int {
    var inchesToMeters: Double { return Double(self) * 0.0254}
}

extension Double {
    var inchesToMeters: Double { return Double(self) * 0.0254}
}



