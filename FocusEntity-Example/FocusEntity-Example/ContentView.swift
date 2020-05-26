//
//  ContentView.swift
//  FocusEntity-Example
//
//  Created by Dilshod Turobov on 5/26/20.
//  Copyright © 2020 Dilshod Turobov. All rights reserved.
//

import SwiftUI
import RealityKit
import FocusEntity

struct ContentView : View {
    var body: some View {
        return FocusEntityView().edgesIgnoringSafeArea(.all)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
