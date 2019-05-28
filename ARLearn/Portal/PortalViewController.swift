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

let POSITION_Y: CGFloat = -WALL_HEIGHT * 0.5
let POSITION_Z: CGFloat = -SURFACE_LENGTH * 0.5

let DOOR_WIDTH: CGFloat = 1.0
let DOOR_HEIGHT: CGFloat = 2.4

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

		let floorNode = makeFloorNode()
		floorNode.position = SCNVector3(x: 0, y: Float(POSITION_Y), z: Float(POSITION_Z))
		portal.addChildNode(floorNode)

		let ceilingNode = makeCeilingNode()
		ceilingNode.position = SCNVector3(0, POSITION_Y + WALL_HEIGHT, POSITION_Z)
		portal.addChildNode(ceilingNode)

		let farWallNode = makeWallNode()
		farWallNode.eulerAngles = SCNVector3(0, 90.0.degreesToRadians, 0)
		farWallNode.position = SCNVector3(0,
																			POSITION_Y + WALL_HEIGHT * 0.5,
																			POSITION_Z - SURFACE_LENGTH * 0.5)
		portal.addChildNode(farWallNode)

		let rightSideWallNode = makeWallNode(maskLowerSide: true)
		rightSideWallNode.eulerAngles = SCNVector3(0, 180.0.degreesToRadians, 0)
		rightSideWallNode.position = SCNVector3(WALL_LENGTH * 0.5,
																						POSITION_Y + WALL_HEIGHT * 0.5,
																						POSITION_Z)
		portal.addChildNode(rightSideWallNode)

		let leftSideWallNode = makeWallNode(maskLowerSide: true)
		leftSideWallNode.position = SCNVector3(-WALL_LENGTH * 0.5,
																					 POSITION_Y + WALL_HEIGHT * 0.5,
																					 POSITION_Z)
		portal.addChildNode(leftSideWallNode)

		addDoorway(node: portal)
		placeLightSource(rootNode: portal)

		return portal
	}

	func addDoorway(node: SCNNode) {
		let halfWallLength: CGFloat = WALL_LENGTH * 0.5
		let frontHalfWallLength: CGFloat = (WALL_LENGTH - DOOR_WIDTH) * 0.5

		let leftDoorSideNode = makeWallNode(length: frontHalfWallLength)
		leftDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
		leftDoorSideNode.position = SCNVector3(-halfWallLength + 0.5 * frontHalfWallLength,
																					 POSITION_Y + WALL_HEIGHT * 0.5,
																					 POSITION_Z + SURFACE_LENGTH * 0.5)
		node.addChildNode(leftDoorSideNode)

		let rightDoorSideNode = makeWallNode(length: frontHalfWallLength)
		rightDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
		rightDoorSideNode.position = SCNVector3(halfWallLength - 0.5 * DOOR_WIDTH,
																						POSITION_Y + WALL_HEIGHT * 0.5,
																						POSITION_Z + SURFACE_LENGTH * 0.5)
		node.addChildNode(rightDoorSideNode)

		let aboveDoorNode = makeWallNode(length: DOOR_WIDTH, height: WALL_HEIGHT - DOOR_WIDTH)
		aboveDoorNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
		aboveDoorNode.position = SCNVector3(0,
																				POSITION_Y + (WALL_HEIGHT - DOOR_HEIGHT) * 0.5 + DOOR_HEIGHT,
																				POSITION_Z + SURFACE_LENGTH * 0.5)
		node.addChildNode(aboveDoorNode)
	}

	func placeLightSource(rootNode: SCNNode) {
		let light = SCNLight()
		light.intensity = 10
		light.type = .omni
		let lightNode = SCNNode()
		lightNode.light = light
		lightNode.position = SCNVector3(0, POSITION_Y + WALL_HEIGHT, POSITION_Z)
		rootNode.addChildNode(lightNode)
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
