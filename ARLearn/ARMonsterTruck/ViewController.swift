//
//  ViewController.swift
//  ARMonsterTruck
//
//  Created by shaoshuai on 2019/5/30.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion

// MARK: - Game State
enum GameState: Int16 {
	case detectSurface
	case hitStartToPlay
	case playGame
}

class ViewController: UIViewController {

	// MARK: - Properties
	var trackingStatus: String = ""
	var statusMessage: String = ""
	var gameState: GameState = .detectSurface
	var focusPoint:CGPoint!
	var focusNode: SCNNode!

	var truckNode: SCNNode!
	var wheelFLNode: SCNNode!
	var wheelFRNode: SCNNode!
	var wheelRLNode: SCNNode!
	var wheelRRNode: SCNNode!

	let wheelRadius: CGFloat = 0.04
	let wheelFrictionSlip: CGFloat = 0.9
	let suspensionMaxTravel: CGFloat = 4.0
	let suspensionMaxForce: CGFloat = 100
	let suspensionRestLength: CGFloat = 0.08
	let suspensionDamping: CGFloat = 2.0
	let suspensionStiffness: CGFloat = 2.0
	let suspensionCompression: CGFloat = 4.0

	var physicalsVehicle: SCNPhysicsVehicle!
	var groundNode: SCNNode!

	var isThrottling = false
	var engineForce: CGFloat = 0
	let defaultEngineForce: CGFloat = 1.0
	var brakingForce: CGFloat = 0
	let defaultBrakingForce: CGFloat = 0.01

	let motionManager = CMMotionManager()
	let steeringClamp: CGFloat = 0.6
	var steeringAngle: CGFloat = 0
	var maximumSpeed: CGFloat = 2.0

	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var startButton: UIButton!
	@IBOutlet var resetButton: UIButton!

	// MARK: Actions
	@IBAction func startButtonPressed(_ sender: Any) {
		self.startGame()
	}

	@IBAction func resetButtonPressed(_ sender: Any) {
		self.resetGame()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.initSceneView()
		self.initScene()
		self.initARSession()
		self.loadModels()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		print("*** ViewWillAppear()")
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		print("*** ViewWillDisappear()")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		print("*** DidReceiveMemoryWarning()")
	}

	override var prefersStatusBarHidden: Bool {
		return true
	}

//	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//		return .landscapeRight
//	}

	// MARK: Init Functions

	func initSceneView() {
		sceneView.delegate = self
		sceneView.automaticallyUpdatesLighting = false
		//sceneView.showsStatistics = true
		//sceneView.preferredFramesPerSecond = 60
		//sceneView.antialiasingMode = .multisampling2X
		sceneView.debugOptions = [
			//ARSCNDebugOptions.showFeaturePoints,
			//ARSCNDebugOptions.showWorldOrigin,
			//SCNDebugOptions.showPhysicsShapes,
			//SCNDebugOptions.showBoundingBoxes
		]

		focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.25)
	}

	func initScene() {
		let scene = SCNScene()
		scene.lightingEnvironment.contents = "MonsterTruck.scnassets/Textures/Environment_CUBE.jpg"
		scene.lightingEnvironment.intensity = 4
		scene.physicsWorld.speed = 1
		//scene.physicsWorld.timeStep = 1.0 / 60.0 // Physics Precision
		scene.isPaused = false
		sceneView.scene = scene
	}

	func initARSession() {

		guard ARWorldTrackingConfiguration.isSupported else {
			print("*** ARConfig: AR World Tracking Not Supported")
			return
		}

		let config = ARWorldTrackingConfiguration()
		config.isLightEstimationEnabled = true
		config.planeDetection = .horizontal
		config.worldAlignment = .gravity
		config.providesAudioData = false
		sceneView.session.run(config)
	}

	func resetARSession() {
		let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
		config.planeDetection = .horizontal
		sceneView.session.run(config,
													options: [.resetTracking,
																		.removeExistingAnchors])
	}

	func suspendARPlaneDetection() {
		let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
		config.planeDetection = []
		sceneView.session.run(config)
	}


	// MARK: Helper Functions

	func createARPlaneNode(planeAnchor: ARPlaneAnchor, color: UIColor) -> SCNNode {

		// 1 - Create plane geometry using anchor extents
		let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
																 height: CGFloat(planeAnchor.extent.z))

		// 2 - Create meterial with just a diffuse color
		let planeMaterial = SCNMaterial()
		planeMaterial.diffuse.contents = color
		planeGeometry.materials = [planeMaterial]

		// 3 - Create plane node
		let planeNode = SCNNode(geometry: planeGeometry)
		planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
		planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)

		return planeNode
	}

	func updateARPlaneNode(planeNode: SCNNode, planeAchor: ARPlaneAnchor) {

		// 1 - Update plane geometry with planeAnchor details
		let planeGeometry = planeNode.geometry as! SCNPlane
		planeGeometry.width = CGFloat(planeAchor.extent.x)
		planeGeometry.height = CGFloat(planeAchor.extent.z)

		// 2 - Update plane position
		planeNode.position = SCNVector3Make(planeAchor.center.x, 0, planeAchor.center.z)
	}

	func removeARPlaneNode(node: SCNNode) {
		for childNode in node.childNodes {
			childNode.removeFromParentNode()
		}
	}

	// MARK: Update Functions

	func updateStatus() {
		switch gameState {
		case .detectSurface: statusMessage = "Detecting surfaces..."
		case .hitStartToPlay: statusMessage = "Hit START to play!"
		case .playGame: statusMessage = "Touch to Throttle, Tilt to Steer!"
		}

		self.statusLabel.text = trackingStatus != "" ?
			"\(trackingStatus)" : "\(statusMessage)"
	}

	func updateFocusNode() {

		// Hide Focus Node
		if gameState == .playGame {
			self.focusNode.isHidden = true
			return
		}

		// Show Focus Node
		self.focusNode.isHidden = false

		let results = self.sceneView.hitTest(self.focusPoint, types: [.existingPlaneUsingExtent])

		if results.count >= 1 {
			if let match = results.first {
				let t = match.worldTransform
				self.focusNode.position = SCNVector3(x: t.columns.3.x, y: t.columns.3.y, z: t.columns.3.z)
				self.gameState = .hitStartToPlay
			}
		} else {
			self.gameState = .detectSurface
		}
	}

	// MARK: Game Management

	func startGame() {
		guard gameState == .hitStartToPlay else {
			return
		}
		DispatchQueue.main.async {
			self.createVhiclePhysics()
			self.updatePositions()
			self.truckNode.isHidden = false
			self.gameState = .playGame
		}
	}

	func resetGame(){
		guard gameState == .playGame else {
			return
		}
		DispatchQueue.main.async {
			self.truckNode.isHidden = true
			self.groundNode.isHidden = true
			self.stopAccelerometer()
			self.gameState = .detectSurface
		}
	}

	func loadModels() {
		let truckScene = SCNScene(named: "MonsterTruck.scnassets/Models/MonsterTruck.scn")!
		truckNode = truckScene.rootNode.childNode(withName: "Truck", recursively: true)!
		wheelFLNode = truckScene.rootNode.childNode(withName: "Wheel_FL", recursively: true)!
		wheelFRNode = truckScene.rootNode.childNode(withName: "Wheel_FR", recursively: true)!
		wheelRLNode = truckScene.rootNode.childNode(withName: "Wheel_RL", recursively: true)!
		wheelRRNode = truckScene.rootNode.childNode(withName: "Wheel_RR", recursively: true)!

		truckNode.addChildNode(wheelFLNode)
		truckNode.addChildNode(wheelFRNode)
		truckNode.addChildNode(wheelRLNode)
		truckNode.addChildNode(wheelRRNode)

		truckNode.isHidden = true
		sceneView.scene.rootNode.addChildNode(truckNode)

		// Load Focus Node
		let focusScene = SCNScene(named: "MonsterTruck.scnassets/Models/Focus.scn")!
		focusNode = focusScene.rootNode.childNode(withName: "Focus", recursively: false)
		focusNode.isHidden = true
		sceneView.scene.rootNode.addChildNode(focusNode)

		groundNode = self.createFloorNode()
		groundNode.isHidden = true
		sceneView.scene.rootNode.addChildNode(groundNode)
	}

	func createPhysicsVehicleWheel(wheelNode: SCNNode, position: SCNVector3) -> SCNPhysicsVehicleWheel {
		let wheel = SCNPhysicsVehicleWheel(node: wheelNode)
		wheel.connectionPosition = position
		wheel.axle = SCNVector3(-1.0, 0, 0)
		wheel.maximumSuspensionTravel = suspensionMaxTravel
		wheel.maximumSuspensionForce = suspensionMaxForce
		wheel.suspensionRestLength = suspensionRestLength
		wheel.suspensionDamping = suspensionDamping
		wheel.suspensionStiffness = suspensionStiffness
		wheel.suspensionCompression = suspensionCompression
		wheel.radius = wheelRadius
		wheel.frictionSlip = wheelFrictionSlip
		return wheel
	}

	func createVhiclePhysics() {
		if physicalsVehicle != nil {
			sceneView.scene.physicsWorld.removeBehavior(physicalsVehicle)
		}
		let wheelFL = createPhysicsVehicleWheel(wheelNode: wheelFLNode,
																						position: SCNVector3(-0.07, 0.04, 0.06))
		let wheelFR = createPhysicsVehicleWheel(wheelNode: wheelFRNode,
																						position: SCNVector3(0.07, 0.04, 0.06))
		let wheelRL = createPhysicsVehicleWheel(wheelNode: wheelRLNode,
																						position: SCNVector3(-0.07, 0.04, -0.06))
		let wheelRR = createPhysicsVehicleWheel(wheelNode: wheelRRNode,
																						position: SCNVector3(0.07, 0.04, -0.06))
		physicalsVehicle = SCNPhysicsVehicle(chassisBody: truckNode.physicsBody!,
																				 wheels: [wheelFL, wheelFR, wheelRL, wheelRR])
		sceneView.scene.physicsWorld.addBehavior(physicalsVehicle)
	}

	func updatePositions() {
		truckNode.position = focusNode.position
		truckNode.position.y += 0.2

		truckNode.physicsBody?.velocity = SCNVector3Zero
		truckNode.physicsBody?.angularVelocity = SCNVector4Zero

		truckNode.physicsBody?.resetTransform()

		groundNode.position = focusNode.position
		groundNode.physicsBody?.resetTransform()
		groundNode.isHidden = false

		self.startAccelerometer()
	}

	func createFloorNode() -> SCNNode {
		let floorGeometry = SCNFloor()
		floorGeometry.reflectivity = 0.0
		let floorMaterial = SCNMaterial()
		floorMaterial.diffuse.contents = UIColor.white
		floorMaterial.blendMode = .multiply
		floorGeometry.materials = [floorMaterial]
		let floorNode = SCNNode(geometry: floorGeometry)
		floorNode.position = SCNVector3Zero
		floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		floorNode.physicsBody?.restitution = 0.5
		floorNode.physicsBody?.friction = 4.0
		floorNode.physicsBody?.rollingFriction = 0.0
		return floorNode
	}

	func startAccelerometer() {
		guard motionManager.isAccelerometerAvailable else {
			return
		}
		motionManager.accelerometerUpdateInterval = 1/60.0
		motionManager.startAccelerometerUpdates(
		to: OperationQueue.main) { (accelerometerData: CMAccelerometerData?, error: Error?) in
			self.updateSteeringAngle(acceleration: accelerometerData!.acceleration)
		}
	}

	func stopAccelerometer() {
		motionManager.stopAccelerometerUpdates()
	}
}




extension ViewController : ARSCNViewDelegate {

	// MARK: - SceneKit Management

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		DispatchQueue.main.async {
			self.updateStatus()
			self.updateFocusNode()
			self.updateVehiclePhysics()
		}
	}

	// MARK: - AR Session State Management

	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		switch camera.trackingState {
		case .notAvailable:
			self.trackingStatus = "Tacking:  Not available!"
			break
		case .normal:
			self.trackingStatus = "" // Tracking Normal
			break
		case .limited(let reason):
			switch reason {
			case .excessiveMotion:
				self.trackingStatus = "Tracking: Limited due to excessive motion!"
				break
			case .insufficientFeatures:
				self.trackingStatus = "Tracking: Limited due to insufficient features!"
				break
			case .relocalizing:
				self.trackingStatus = "Tracking: Resuming..."
				break
			case .initializing:
				self.trackingStatus = "Tracking: Initializing..."
				break
			@unknown default:
				self.trackingStatus = "Tracking: unknown..."
			}
		}
	}

	// MARK: - AR Session Error Managent

	func session(_ session: ARSession, didFailWithError error: Error) {
		// Present an error message to the user
		self.trackingStatus = "AR Session Failure: \(error)"
	}

	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay
		self.trackingStatus = "AR Session Was Interrupted!"
	}

	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required
		self.trackingStatus = "AR Session Interruption Ended"
		self.resetGame()
	}

	// MARK: - Plane Management

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
		DispatchQueue.main.async {
			let planeNode = self.createARPlaneNode(
				planeAnchor: planeAnchor,
				color: UIColor.blue.withAlphaComponent(0))
			node.addChildNode(planeNode)
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
		DispatchQueue.main.async {
			self.updateARPlaneNode(
				planeNode: node.childNodes[0],
				planeAchor: planeAnchor)
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
		guard anchor is ARPlaneAnchor else { return }
		DispatchQueue.main.async {
			self.removeARPlaneNode(node: node)
		}
	}
}

extension ViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		isThrottling = true
	}
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		isThrottling = false
	}

	func updateVehiclePhysics() {
		guard gameState == .playGame else {
			return
		}
		if isThrottling {
			engineForce = defaultEngineForce
			brakingForce = 0
		} else {
			engineForce = 0
			brakingForce = defaultBrakingForce
		}
		physicalsVehicle.applyEngineForce(engineForce, forWheelAt: 0)
		physicalsVehicle.applyEngineForce(engineForce, forWheelAt: 1)
		physicalsVehicle.applyEngineForce(engineForce, forWheelAt: 2)
		physicalsVehicle.applyEngineForce(engineForce, forWheelAt: 3)

		physicalsVehicle.applyBrakingForce(brakingForce, forWheelAt: 0)
		physicalsVehicle.applyBrakingForce(brakingForce, forWheelAt: 1)
		physicalsVehicle.applyBrakingForce(brakingForce, forWheelAt: 2)
		physicalsVehicle.applyBrakingForce(brakingForce, forWheelAt: 3)

		physicalsVehicle.setSteeringAngle(steeringAngle, forWheelAt: 0)
		physicalsVehicle.setSteeringAngle(steeringAngle, forWheelAt: 1)

		if physicalsVehicle.speedInKilometersPerHour > maximumSpeed {
			engineForce = 0
		}
	}

	func updateSteeringAngle(acceleration: CMAcceleration) {
		steeringAngle = CGFloat(acceleration.y)
		if steeringAngle < -steeringClamp {
			steeringAngle = -steeringClamp
		} else if steeringAngle > steeringClamp {
			steeringAngle = steeringClamp
		}
	}
}
