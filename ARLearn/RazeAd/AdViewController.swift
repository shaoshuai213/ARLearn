//
//  AdViewController.swift
//  RazeAd
//
//  Created by shaoshuai on 2019/5/29.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

final class AdViewController: UIViewController, ARSCNViewDelegate {

	@IBOutlet var sceneView: ARSCNView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set the view's delegate
		sceneView.delegate = self

		// Show statistics such as fps and timing information
		sceneView.showsStatistics = true

		// Create a new scene
		let scene = SCNScene(named: "art.scnassets/ship.scn")!

		// Set the scene to the view
		sceneView.scene = scene
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Create a session configuration
		let configuration = ARWorldTrackingConfiguration()

		// Run the view's session
		sceneView.session.run(configuration)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Pause the view's session
		sceneView.session.pause()
	}

	// MARK: - ARSCNViewDelegate

	/*
	// Override to create and configure nodes for anchors added to the view's session.
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
	let node = SCNNode()

	return node
	}
	*/

	func session(_ session: ARSession, didFailWithError error: Error) {
		// Present an error message to the user

	}

	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay

	}

	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required

	}
}

extension AdViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let currentFrame = sceneView.session.currentFrame else {
			return
		}

		DispatchQueue.global(qos: .background).async {
			do {
				let request = VNDetectRectanglesRequest.init(completionHandler: { (request, error) in
					guard let result = request.results?.compactMap({ $0 as? VNRectangleObservation }).first else {
						print("[Vision] VNRequest produced no result]")
						return
					}
					let coordinates: [matrix_float4x4] = [
						result.topLeft,
						result.topRight,
						result.bottomRight,
						result.bottomLeft
						].compactMap {
							guard let hitFeature = currentFrame.hitTest($0, types: .featurePoint).first else {
								return nil
							}
							return hitFeature.worldTransform
						}

					guard coordinates.count == 4 else { return }

					DispatchQueue.main.async {
						self.removeBillboard()
						let (topLeft, topRight, bottomRight, bottomLeft) = (coordinates[0], coordinates[1], coordinates[2], coordinates[3])
						self.createBillboard(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
					}
				})
				let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage)
				try handler.perform([request])
			} catch let error {
				print("An error occured during rectangle \(error)")
			}
		}
	}
}

extension AdViewController {
	func createBillboard(topLeft: matrix_float4x4,
											 topRight: matrix_float4x4,
											 bottomRight: matrix_float4x4,
											 bottomLeft: matrix_float4x4) {
//		let plane = RectangularPlane()
	}

	func removeBillboard() {
//		if let anchor = billboard?.billboardAnchor {
//			sceneView.session.remove(anchor: anchor)
//
//		}
	}
}
