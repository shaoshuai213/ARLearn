//
//  ViewController.swift
//  ARPokerDice
//
//  Created by shaoshuai on 2019/5/27.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class PokerDiceViewController: UIViewController {

	//	MARK: - Properties
	private var trackingStatus: String = "Greeting! :]" {
		didSet {
			DispatchQueue.main.async {
				self.statusLabel.text = self.trackingStatus
			}
		}
	}

	private lazy var diceNodes: [SCNNode] = {
		var disceNodes: [SCNNode] = []
		let diceScene = SCNScene(named: "PokerDice.scnassets/DiceScene.scn")!
		for index in 0..<5 {
			let node = diceScene.rootNode.childNode(withName: "dice\(index)", recursively: false)!
			disceNodes.append(node)
		}
		return disceNodes
	}()

	private var diceCount: Int = 5
	private var diceStyle: Int = 0
	private var diceOffset: [SCNVector3] = [
		SCNVector3( 0.00,  0.00,  0.00),
		SCNVector3(-0.05,  0.00,  0.00),
		SCNVector3( 0.05,  0.00,  0.00),
		SCNVector3(-0.05,  0.05,  0.02),
		SCNVector3( 0.05,  0.05,  0.02)
	]

	private lazy var focusNode: SCNNode = {
		let scene = SCNScene(named: "PokerDice.scnassets/FocusScene.scn")!
		let focusNode = scene.rootNode.childNode(withName: "focus", recursively: false)!
		return focusNode
	}()


	//	MARK: - Outlets

	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var startButton: UIButton!
	@IBOutlet weak var styleButton: UIButton!
	@IBOutlet weak var resetButton: UIButton!

	//	MARK: - Actions

	@IBAction func startButtonPressed() {

	}

	@IBAction func styleButtonPressed() {
		diceStyle = diceStyle >= 4 ? 0 : diceStyle + 1
	}

	@IBAction func resetButtonPressed() {

	}

	@IBAction func swipeUpGestureHandler() {
		guard let frame = self.sceneView.session.currentFrame else {
			return
		}
		for index in 0..<diceCount {
			throwDiceNode(transform: SCNMatrix4(frame.camera.transform), offset: diceOffset[index])
		}
	}

	//	MARK: - View Management

	override func viewDidLoad() {
		super.viewDidLoad()

		statusLabel.text = trackingStatus
		initSceneView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		initARSession()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Pause the view's session
		sceneView.session.pause()
	}

	//	MARK: - Initialization

	private func initSceneView() {
		let scene = SCNScene()
		scene.lightingEnvironment.contents = "PokerDice.scnassets/Textures/Environment_CUBE.jpg"
		scene.lightingEnvironment.intensity = 2
		sceneView.scene = scene
//		sceneView.debugOptions = [.showFeaturePoints,
//															.showWorldOrigin,
//															.showBoundingBoxes,
//															.showWireframe]
		sceneView.delegate = self
		sceneView.scene.rootNode.addChildNode(focusNode)
	}

	private func initARSession() {
		guard ARWorldTrackingConfiguration.isSupported else {
			print("*** ARConfig: AR World Tracking Not Supported")
			return
		}

		let config = ARWorldTrackingConfiguration()
		config.worldAlignment = .gravity
		config.providesAudioData = false
		sceneView.session.run(config)
	}
}

extension PokerDiceViewController {
	func throwDiceNode(transform: SCNMatrix4, offset: SCNVector3) {
		let position = SCNVector3(transform.m41 + offset.x,
															transform.m42 + offset.y,
															transform.m43 + offset.z)
		let diceNode = diceNodes[diceStyle].clone()
		diceNode.name = "dice"
		diceNode.position = position
		sceneView.scene.rootNode.addChildNode(diceNode)
//		diceCount -= 1
	}
}

// MARK: - ARSCNViewDelegate

extension PokerDiceViewController: ARSCNViewDelegate {

	func session(_ session: ARSession, didFailWithError error: Error) {
		trackingStatus = "AR Session Failure: \(error)"
	}

	func sessionWasInterrupted(_ session: ARSession) {
		trackingStatus = "AR Session Was Interrupted!"
	}

	func sessionInterruptionEnded(_ session: ARSession) {
		trackingStatus = "AR Session Interruption Ended!"
	}

	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		switch camera.trackingState {
		case .notAvailable:
			trackingStatus = "Tracking: Not available!"
		case .normal:
			trackingStatus = "Tracking: All good!"
		case .limited(let reason):
			switch reason {
			case .excessiveMotion:
				trackingStatus = "Tracking: Limited due to excessive motion!"
			case .insufficientFeatures:
				trackingStatus = "Tracking: Limited due to insufficient features!"
			case .initializing:
				trackingStatus = "Tracking: Initializing..."
			case .relocalizing:
				trackingStatus = "Tracking: Relocalizing"
			@unknown default:
				trackingStatus = "Tracking: unknown default"
			}
		}
	}

}

extension PokerDiceViewController: SCNSceneRendererDelegate {

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		DispatchQueue.main.async {
//			self.statusLabel.text = self.trackingStatus
		}
	}

}

extension PokerDiceViewController {
	override var prefersStatusBarHidden: Bool {
		return true
	}
}
