//
//  SCNNodeHelpers.swift
//  Portal
//
//  Created by shaoshuai on 2019/5/28.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import Foundation
import SceneKit

func createPlaneNode(center: vector_float3,
										 extent: vector_float3) -> SCNNode {
	let plane = SCNPlane(width: CGFloat(extent.x),
											 height: CGFloat(extent.z))
	let planeMaterial = SCNMaterial()
	planeMaterial.diffuse.contents = UIColor.yellow.withAlphaComponent(0.4)
	plane.materials = [planeMaterial]
	let planeNode = SCNNode(geometry: plane)
	planeNode.position = SCNVector3(x: center.x, y: 0, z: center.z)
	planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
	return planeNode
}

func updatePlaneNode(_ node: SCNNode,
										 center: vector_float3,
										 extent: vector_float3) {
	guard let geometry = node.geometry as? SCNPlane else {
		return
	}
	geometry.width = CGFloat(extent.x)
	geometry.height = CGFloat(extent.z)
	node.position = SCNVector3(x: center.x, y: 0, z: center.z)
}
