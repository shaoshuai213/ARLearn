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

enum GameState: Int16 {
	case detectSurface
	case pointToSurface
	case swipeToPlay
}

final class PokerDiceViewController: UIViewController {

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

	private var gameState: GameState = .detectSurface
	private var statusMessage: String = ""

	var focusPoint: CGPoint = .zero

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

		focusPoint = CGPoint(x: view.center.x, y: view.center.y * 1.25)
		NotificationCenter.default.addObserver(self,
																					 selector: #selector(orientationChanged),
																					 name: UIDevice.orientationDidChangeNotification,
																					 object: nil)
	}

	private func initARSession() {
		guard ARWorldTrackingConfiguration.isSupported else {
			print("*** ARConfig: AR World Tracking Not Supported")
			return
		}

		let config = ARWorldTrackingConfiguration()
		config.worldAlignment = .gravity
		config.providesAudioData = false
		config.planeDetection = .horizontal
		sceneView.session.run(config)
	}

	func updateStatus() {
		switch gameState {
		case .detectSurface:
			statusMessage = "Scan entire table surface...\nHit START when ready!"
		case .pointToSurface:
			statusMessage = "Point at designated surface first!"
		case .swipeToPlay:
			statusMessage = "Swipe UP to throw!\nTap on dice to collect it again."
		}
		self.statusLabel.text = statusMessage
	}

	func createARPlaneNode(planeAnchor: ARPlaneAnchor, color: UIColor) -> SCNNode {
		let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
																 height: CGFloat(planeAnchor.extent.z))
		let planeMaterial = SCNMaterial()
		planeMaterial.diffuse.contents = "PokerDice.scnassets/Textures/Surface_DIFFUSE.png"
		planeGeometry.materials = [planeMaterial]
		let planeNode = SCNNode(geometry: planeGeometry)
		planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
		planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
		return planeNode
	}

	func updateARPlaneNode(planeNode: SCNNode, planeAnchor: ARPlaneAnchor) {
		let planeGeometry = planeNode.geometry as! SCNPlane
		planeGeometry.width = CGFloat(planeAnchor.extent.x)
		planeGeometry.height = CGFloat(planeAnchor.extent.z)
		planeNode.position = SCNVector3(x: planeAnchor.center.x,
																		y: 0,
																		z: planeAnchor.center.z)
	}

	func updateFocusNode() {
		let results = sceneView.hitTest(focusPoint, types: [.existingPlaneUsingExtent])
		if results.count == 1 {
			let match = results[0]
			let t = match.worldTransform
			focusNode.position = SCNVector3(x: t.columns.3.x,
																			y: t.columns.3.y,
																			z: t.columns.3.z)
			gameState = .swipeToPlay
		} else {
			gameState = .pointToSurface
		}
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
			self.updateStatus()
			self.updateFocusNode()
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else {
			return
		}
		DispatchQueue.main.async {
			let planeNode = self.createARPlaneNode(planeAnchor: planeAnchor,
																						 color: UIColor.yellow.withAlphaComponent(0.5))
			node.addChildNode(planeNode)
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else {
			return
		}
		DispatchQueue.main.async {
			self.updateARPlaneNode(planeNode: node.childNodes[0], planeAnchor: planeAnchor)
		}
	}

}

extension PokerDiceViewController {
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

extension PokerDiceViewController {
	@objc func orientationChanged() {
		focusPoint = CGPoint(x: view.center.x, y: view.center.y * 1.25)
	}
}
