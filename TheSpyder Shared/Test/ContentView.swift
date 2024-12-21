//
//  ContentView.swift
//  Test
//
//  Created by Hyung Lee on 10/18/24.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    let context = TSGameContext(dependencies: .init())
    let screenSize: CGSize = UIScreen.main.bounds.size
    
    var body: some View {
        SpriteView(scene: TSGameScene(context: context,
                                      size: screenSize))
    }
}

#Preview {
    ContentView()
        .ignoresSafeArea()
}
