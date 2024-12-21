import Combine
import GameplayKit
import SwiftUI

class TSGameContext: GameContext {
    var gameScene: TSGameScene? {
        scene as? TSGameScene
    }
    
    let gameInfo: TSGameInfo
    var layoutInfo: TSLayoutInfo = .init(screenSize: CGSizeZero)

    override init(dependencies: Dependencies) {
        self.gameInfo = TSGameInfo()
        super.init(dependencies: dependencies)
    }
   
    func updateLayoutInfo(withScreenSize size: CGSize){
        layoutInfo = TSLayoutInfo(screenSize: size)
    }
}
