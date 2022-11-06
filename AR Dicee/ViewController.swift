//
//  ViewController.swift
//  AR Dicee
//
//  Created by Cory Carte on 9/21/22.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    //MARK: - Variable Declarations
    let debug = false // Run with various debug options
    var gridTransparency = 0.0
    var diceArray = [SCNNode]()
    @IBOutlet var sceneView: ARSCNView!
    
    //MARK: - IBActions
    @IBAction func rollAgain(_ sender: Any) {
        rollAll()
    }
    
    @IBAction func removeAllDice(_ sender: Any) {
        if !diceArray.isEmpty {
            for d in diceArray {
                d.removeFromParentNode()
            }
        }
        
        diceArray = [SCNNode]()
    }
    
    //MARK: - ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Debug options
        if debug {
            // Show AR Scene feature points
            self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            
            // Show statistics such as fps and timing information
            self.sceneView.showsStatistics = true
            self.gridTransparency = 0.35
        }
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: - AR Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // When touch is registered in the view
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView) // in wants where the touch was perceived (within the scene)
            
            // TODO - hitTest is deprecated. Update
            let results = sceneView.hitTest(touchLocation, types: .existingPlane) // convert the 2D touch into a 3D coordinate (add Z point)
            
            if let hitResult = results.first {
                addDice(atLocation: hitResult)
            }
        }
    }
    
    // ARHitTestResult deprecated, use raycasting
    func addDice(atLocation location: ARHitTestResult) {
        // Create a new dice object
        let scene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        if let diceNode = scene.rootNode.childNode(withName: "Dice", recursively: true) {
            // unwrap the hitresult position's x/y/z coord positions
            diceNode.position = SCNVector3(x: location.worldTransform.columns.3.x,
                                           y: (location.worldTransform.columns.3.y + diceNode.boundingSphere.radius),
                                           z: location.worldTransform.columns.3.z
            )
            
            // Add the dice to the scene
            sceneView.scene.rootNode.addChildNode(diceNode)
            diceArray.append(diceNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlane(withAnchor: planeAnchor)
        
        node.addChildNode(planeNode)
    }
    
    //MARK: - Dice Methods
    func roll(_ dice: SCNNode) {
        // Randomize dice results
        let randomX = CGFloat(Float(arc4random_uniform(4) + 1) * (Float.pi / 2)) // Rotate die around X axis
        let randomZ = CGFloat(Float(arc4random_uniform(4) + 1) * (Float.pi / 2)) // Rotate die around Z axis
        
        dice.runAction(SCNAction.rotateBy(
            x: randomX * 5, // increase rotation of animation
            y: 0,
            z: randomZ * 5, // increase rotation of animation
            duration: 0.5
        ))
    }
    
    func rollAll() {
        if !diceArray.isEmpty {
            for d in diceArray {
                roll(d)
            }
        }
    }
    
    //MARK: - Plane Rendering
    func createPlane(withAnchor anchor: ARPlaneAnchor) -> SCNNode {
        // Set scene plane the size of the given anchor
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z)) // Z is commonly confused with Y for planes. See docs: <DOCLINK>
        
        // Create a node to attach the plane to
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: anchor.center.x, y: 0, z: anchor.center.z)
        
        // SCNPlane is created as a vertically oriented object. We must rotate 90 deg
        // SCNMatrix4MakeRotation angle is in Radians (90 deg -> PI/2 rad)
        //                              rotation is counter clockwise, to force clockwise, make negative
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        // Create a grid material and assign it to the plane
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        gridMaterial.transparency = CGFloat(self.gridTransparency)
        
        plane.materials = [gridMaterial]
        
        // Assign the plane geometery and attach node
        planeNode.geometry = plane
        
        return planeNode
    }
}
