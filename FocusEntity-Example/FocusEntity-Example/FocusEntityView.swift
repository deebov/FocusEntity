//
//  FocusEntityView.swift
//  FocusEntity-Example
//
//  Created by Dilshod Turobov on 5/26/20.
//  Copyright © 2020 Dilshod Turobov. All rights reserved.
//

import FocusEntity
import Combine
import SwiftUI
import RealityKit

struct FocusEntityView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let focusEntity = FocusSquare()
        focusEntity.arViewDelegate = arView
        focusEntity.setAutoUpdate(to: true)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}
