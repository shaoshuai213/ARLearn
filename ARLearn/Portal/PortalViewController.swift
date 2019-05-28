//
//  PortalViewController.swift
//  Portal
//
//  Created by shaoshuai on 2019/5/28.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class PortalViewController: UIViewController {

	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet var messageLabel: UILabel!
	@IBOutlet var sessionStateLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()

		resetLabels()
		runSession()
	}

	func runSession() {
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		configuration.isLightEstimationEnabled = true
		sceneView.session.run(configuration)
		#if DEBUG
		sceneView.debugOptions = [.showFeaturePoints]
		#endif
	}

	func resetLabels() {
		messageLabel.alpha = 1.0
		messageLabel.text = "Move the phone around and allow the app to find a plane." +
		"You will see a yellow horizontal plane."
		sessionStateLabel.alpha = 0.0
		sessionStateLabel.text = ""
	}
}

// MARK: - ARSCNViewDelegate

extension PortalViewController: ARSCNViewDelegate {

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor {
				let planeNode = createPlaneNode(center: planeAnchor.center,
																				extent: planeAnchor.extent)
				node.addChildNode(planeNode)
				self.messageLabel.text = "Tap on the detected horizontal plane to place the portal"
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor, node.childNodes.count > 0 {
				updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
			}
		}
	}

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
