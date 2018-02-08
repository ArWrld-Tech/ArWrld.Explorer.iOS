//
//  TagNode.swift
//  ArWrld
//
//  Created by David Hodge on 12/16/17.
//  Copyright © 2017 David Hodge. All rights reserved.
//

import SceneKit
import Vision

class TagNode: SCNNode {
    
    var classificationObservation: VNClassificationObservation? {
        didSet {
            addTextNode()
        }
    }
    
    private func addTextNode() {
        guard let text = classificationObservation?.identifier else {return}
        let shorten = text.components(separatedBy: ", ").first!
        let bubble = SCNText(string: shorten, extrusionDepth: 0.01)
        let font = UIFont(name: "Futura", size: 0.15)
        bubble.font = font
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(0.01)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, 0.01/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        
        self.center(node: bubbleNode);
        DispatchQueue.main.async(execute: {
            self.addChildNode(bubbleNode);
        })
//        addSphereNode(color: UIColor.green)
    }
    
    private func addSphereNode(color: UIColor) {
        DispatchQueue.main.async(execute: {
            let node = SCNNode();
            node.geometry = SCNSphere(radius: 0.01)
             self.center(node: node);
            self.addChildNode(node)
        })
    }
    
    func center(node: SCNNode) {
        let (min, max) = node.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
}
