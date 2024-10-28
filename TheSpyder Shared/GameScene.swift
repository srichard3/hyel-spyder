//
//  GameScene.swift
//  TheSpyder Shared
//
//  Created by Rafael Niebles on 10/27/24.
//

import SpriteKit

class GameScene: SKScene {
    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0
    
    let tBackground = SKTexture(imageNamed: "road")
    
    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!
    
    var scrollingSpeed: CGFloat = 250
    
    override func didMove(to view: SKView) {
        // Setup textures
        
        tBackground.filteringMode = .nearest
        
        // Setup sprites
        
        backgroundA = SKSpriteNode(texture: tBackground)
        
        backgroundA.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        
        // Get scale needed to make background fill screen on both axes; apply the largest
        
        let xScaleFactor = view.frame.width / tBackground.size().width
        let yScaleFactor = view.frame.height / tBackground.size().height
        
        backgroundA.setScale(max(xScaleFactor, yScaleFactor))
        
        addChild(backgroundA)
        
        backgroundB = backgroundA.copy() as? SKSpriteNode
        
        backgroundB.position.y = backgroundA.position.y + backgroundA.size.height
        
        addChild(backgroundB)
    }
    
    func scrollBackground() {
        let dy = CGFloat(scrollingSpeed) * deltaTime
                
        // Move to bottom until off-screen, move to top and restart
        
        print("a: \(backgroundA.frame.maxY), b: \(backgroundB.frame.maxY), dt \(deltaTime)")
        
        if backgroundA.position.y <= -backgroundA.size.height / 2 {
            backgroundA.position.y = backgroundB.position.y + backgroundB.size.height - dy
        } else {
            backgroundA.position.y -= dy
        }
        
        if backgroundB.position.y <= -backgroundB.size.height / 2 {
            backgroundB.position.y = backgroundA.position.y + backgroundA.size.height - dy
        } else {
            backgroundB.position.y -= dy
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = currentTime - lastUpdateTime as CGFloat
        
        scrollBackground()
        
        lastUpdateTime = currentTime
    }
}
