//
//  ARSCNView.swift
//  ArWrld
//
//  Created by David Hodge on 2/6/18.
//  Copyright © 2018 David Hodge. All rights reserved.
//

import SceneKit
import ARKit

extension ARSCNView {
    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
        let results = self.hitTest(screenPosition, types: [.featurePoint])
        guard let result = results.first else { return nil }
        return SCNVector3.positionFromTransform(result.worldTransform)
    }
}
