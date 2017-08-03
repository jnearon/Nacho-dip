//
//  GameViewController.swift
//  NachoDip
//
//  Created by Evrhet Milam on 8/2/17.
//  Copyright © 2017 Jacob Nearon. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    
    var scnView: SCNView!
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    
    let minChipCreationInterval: TimeInterval = 0.1
    var chipCreationTime: TimeInterval = 0
    var chipCreationInterval: TimeInterval = 3.0
    var chipsThrown: Int = 0
    var selectedChip: SCNNode?
    var selectedChipPosition: SCNVector3?
    
    var gameStartedTime: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         // retrieve the SCNView
        scnView = self.view as! SCNView
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // auto enable lights
        scnView.autoenablesDefaultLighting = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        scnView.delegate = self
        
        self.initScene()
        self.initCamera()
        
    }

    func initScene() {
        self.gameScene = SCNScene()
        scnView.scene = self.gameScene
        
        scnView.isPlaying = true
    }
    
    func initCamera() {
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        
        self.gameScene.rootNode.addChildNode(self.cameraNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if self.gameStartedTime == 0 {
            self.gameStartedTime = time
        }
        
        if time > self.chipCreationTime {
            self.chipCreationTime = time + chipCreationInterval
            self.createChip()
            self.cleanupChips()
        }
        
        // If we have a selected chip and there is a new position for it then update it
        if let selectedChip = self.selectedChip, let position = self.selectedChipPosition {
            self.selectedChipPosition = nil
            selectedChip.position = position
        }
    }

    func cleanupChips() {
        for eachNode in self.gameScene.rootNode.childNodes {
            if eachNode.presentation.position.y < -3 {
                eachNode.removeFromParentNode()
            }
        }
    }
    
    func createChip() {
        let geometry = SCNPyramid(width: 2.0, height: 2.0, length: 0.2)
        geometry.materials.first?.diffuse.contents = UIColor.yellow
        let node = SCNNode(geometry: geometry)
        node.name = "chip"
        
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.gameScene.rootNode.addChildNode(node)
        
        let xDirection: Float = arc4random_uniform(2) == 0 ? 1.0 : -1.0
        let direction = SCNVector3(x: xDirection, y: 15.0, z: 0.0)
        let pushAt = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        node.physicsBody?.applyForce(direction, at: pushAt, asImpulse: true)
        
        self.chipsThrown += 1
        if self.chipsThrown % 5 == 0 {
            self.chipCreationInterval = max(self.minChipCreationInterval, self.chipCreationInterval - 0.1)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.scnView)
        
        let hitList = self.scnView.hitTest(location, options: nil)
        
        guard let chip = hitList.filter({ $0.node.name ?? "" == "chip" }).first else { return }
        
        self.selectedChip = chip.node
        self.selectedChip?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let _ = self.selectedChip else { return }
        
        let location = touch.location(in: self.scnView)
        
        self.selectedChipPosition = SCNVector3(x: Float(location.x), y: Float(location.y), z: 0.0)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else { return }
        guard let selectedChip = self.selectedChip else { return }
        
        self.selectedChip = nil
        
        selectedChip.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
