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
	private var trackingStatus: String = ""

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

	}

	@IBAction func resetButtonPressed() {

	}

	//	MARK: - View Management

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set the view's delegate
		sceneView.delegate = self

		// Show statistics such as fps and timing information
		sceneView.showsStatistics = true

		// Create a new scene
		let scene = SCNScene(named: "PokerDice.scnassets/SimpleScene.scn")!

		// Set the scene to the view
		sceneView.scene = scene

		statusLabel.text = "Greeting! :]"
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
			self.statusLabel.text = self.trackingStatus
		}
	}

}

extension PokerDiceViewController {
	override var prefersStatusBarHidden: Bool {
		return true
	}
}
