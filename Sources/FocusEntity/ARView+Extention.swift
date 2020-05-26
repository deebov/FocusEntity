//
//  ARView+Extention.swift
//  
//
//  Created by Dilshod Turobov on 5/26/20.
//
import ARKit
import RealityKit

extension ARView {
    // - Tag: CastRayForFocusSquarePosition
    @available(iOS 13, *)
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }

    // - Tag: GetRaycastQuery
    @available(iOS 13, *)
    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        return makeRaycastQuery(from: center, allowing: .estimatedPlane, alignment: alignment)
    }
}
