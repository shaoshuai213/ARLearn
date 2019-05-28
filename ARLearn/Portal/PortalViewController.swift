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

	var planeNodes: [SCNNode] = []
	var viewCenter: CGPoint {
		let viewBounds = view.bounds
		return CGPoint(x: viewBounds.width / 2, y: viewBounds.height / 2)
	}

	var portalNode: SCNNode?
	var isPortalPlaced = false

	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var sessionStateLabel: UILabel!
	@IBOutlet weak var crosshair: UIView!

	override func viewDidLoad() {
		super.viewDidLoad()

		resetLabels()
		runSession()
	}

	func runSession() {
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		configuration.isLightEstimationEnabled = true
		sceneView.session.run(configuration,
													options: [.resetTracking, .removeExistingAnchors])
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

	func showMessage(_ message: String, label: UILabel, seconds: Double) {
		label.text = message
		label.alpha = 1

		DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
			if label.text == message {
				label.text = ""
				label.alpha = 0
			}
		}
	}

	func removeAllNodes() {
		removePlaneNodes()
		portalNode?.removeFromParentNode()
		isPortalPlaced = false
	}

	func removePlaneNodes() {
		planeNodes.forEach { (node) in
			node.removeFromParentNode()
		}
		planeNodes = []
	}

	func makePortal() -> SCNNode {
		let portal = SCNNode()
		let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0)
		let boxNode = SCNNode(geometry: box)
		portal.addChildNode(boxNode)
		return portal
	}
}

// MARK: - ARSCNViewDelegate

extension PortalViewController: ARSCNViewDelegate {

	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		DispatchQueue.main.async {
			if let _ = self.sceneView.hitTest(self.viewCenter, types: [.existingPlaneUsingExtent]).first {
				self.crosshair.backgroundColor = .green
			} else {
				self.crosshair.backgroundColor = .lightGray
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor, !self.isPortalPlaced {
				let planeNode = createPlaneNode(center: planeAnchor.center,
																				extent: planeAnchor.extent)
				node.addChildNode(planeNode)
				self.planeNodes.append(planeNode)
				self.messageLabel.alpha = 1.0
				self.messageLabel.text = "Tap on the detected horizontal plane to place the portal"
			} else if !self.isPortalPlaced {
				self.portalNode = self.makePortal()
				if let portal = self.portalNode {
					node.addChildNode(portal)
					self.isPortalPlaced = true
					self.removePlaneNodes()
					self.sceneView.debugOptions = []
					self.messageLabel.text = ""
					self.messageLabel.alpha = 0
				}
			}
		}
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		DispatchQueue.main.async {
			if let planeAnchor = anchor as? ARPlaneAnchor, node.childNodes.count > 0, !self.isPortalPlaced {
				updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
			}
		}
	}

	func session(_ session: ARSession, didFailWithError error: Error) {
		showMessage(error.localizedDescription, label: sessionStateLabel, seconds: 3)
	}

	func sessionWasInterrupted(_ session: ARSession) {
		showMessage("Session interrupted", label: sessionStateLabel, seconds: 3)
	}

	func sessionInterruptionEnded(_ session: ARSession) {
		showMessage("Session resumed", label: sessionStateLabel, seconds: 3)
		DispatchQueue.main.async {
			self.removeAllNodes()
			self.resetLabels()
		}
		runSession()
	}
}

extension PortalViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
			sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
		}
	}
}
