import Combine
import GameplayKit
import SwiftUI

class TSGameContext: GameContext {
    var gameScene: TSGameScene? {
        scene as? TSGameScene
    }
    let gameMode: GameModeType
    let gameInfo: TSGameInfo
    var layoutInfo: TSLayoutInfo = .init(screenSize: CGSizeZero)

    init(dependencies: Dependencies, gameMode: GameModeType) {
        self.gameMode = gameMode
        self.gameInfo = TSGameInfo()
        super.init(dependencies: dependencies)
        
        self.scene = TSGameScene(context: self, size: UIScreen.main.bounds.size)
    }
   
    func updateLayoutInfo(withScreenSize size: CGSize){
        layoutInfo = TSLayoutInfo(screenSize: size)
    }
}
