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
    
//    let buttonTopScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")
    var buttonTopScene = SCNScene()
    var buttonTopNode = SCNNode()
 
    //    let buttonBaseScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")
    var buttonBaseScene = SCNScene()
    var buttonBaseNode = SCNNode()
    
    var buttonAdded: Bool = false
    var QRReader: Bool = true
    var detectedCenterAnchor: ARAnchor?
    var processing = false
    var created = false
    let QR1 = "picasso"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        self.sceneView.session.delegate = self

        
        insertSpotLight(position: SCNVector3(0,3.0,1.0))
    
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
            imageView.isHidden = false
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
    
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // don't keep looking once it's placed
        if self.buttonAdded {
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
                                self.imageView.stopAnimating()
                                self.imageView.isHidden = true
                                
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
            
            // Button Top Node
            self.buttonTopScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")!
            self.buttonTopNode = (self.buttonTopScene.rootNode.childNode(withName: "Top", recursively: true))!
            
            self.buttonTopNode.position = SCNVector3(0,0,0)
           
            // Button Bottom Node
            self.buttonBaseScene = SCNScene(named: "Models.scnassets/Button_V1.3.scn")!
            self.buttonBaseNode = (self.buttonBaseScene.rootNode.childNode(withName: "Base", recursively: true))!
            self.buttonBaseNode.position = SCNVector3(0,0,0)
            
            let wrapperNode = SCNNode()
            wrapperNode.addChildNode(self.buttonTopNode)
            wrapperNode.addChildNode(self.buttonBaseNode)
            
            //wrapper may not be necessary w/o scn but use for now
            wrapperNode.transform = SCNMatrix4(anchor.transform)
           
            self.buttonAdded = true
            QRReader = false
            
            return wrapperNode
            

        }
        
        return nil
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
            self.pressButton(node: buttonTopNode)
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
    
    @IBAction func reset(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
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



