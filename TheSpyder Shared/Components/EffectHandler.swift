import SpriteKit

class EffectHandler {
    static let shared = EffectHandler()

    let slowdownDuration = 5.0
    let spawnBlockDuration = 1.0

    var overlaySprite: SKSpriteNode?
    
    var timer: Timer?

    public func configure(overlay: SKTexture, targetScene: SKScene){
        self.overlaySprite = SKSpriteNode(texture: overlay)
        
        if let overlaySprite = self.overlaySprite, let view = targetScene.view {
            // Add node to scene
            targetScene.addChild(overlaySprite)
            
            // Make the overlay sprite cover the entire screen
            overlaySprite.size.width = view.frame.width
            overlaySprite.size.height = view.frame.height
            
            overlaySprite.position.x = view.frame.midX
            overlaySprite.position.y = view.frame.midY
            
            // It should also be on top of everything
            overlaySprite.zPosition = 999
            
            // Make it "hidden" by default; control this with opacity for consistency
            overlaySprite.alpha = 0
        }
    }
   
    /// Start overlay with fadeout
    func showOverlay(duration: CGFloat, color: CGColor){
        if let overlaySprite = self.overlaySprite {
            // Turn the overlay on
            overlaySprite.alpha = 1
           
            // Fade it out over the duration
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: duration)
            
            overlaySprite.run(fadeOut)
        }
    }
    
    /// Begins run of a specified effect
    func runEffect(for type: GameObjectType){
        // This is the duration that our run of the next effect will have
        var selectedDuration: TimeInterval
      
        // Select it!
        switch type {
        case .horn:
            selectedDuration = spawnBlockDuration
        case .freshener:
            selectedDuration = 0
        case .drink:
            selectedDuration = slowdownDuration
        default:
            selectedDuration = 0
        }
       
        // Apply powerup effect
        setEffect(for: type)
       
        // Run the timer, unsetting the effect at completion
        timer = Timer.scheduledTimer(withTimeInterval: selectedDuration, repeats: false) { timer in
            self.unsetEffect(for: type)
            timer.invalidate()
        }
    }
   
    /// Apply the powerup's effect
    func setEffect(for type: GameObjectType){
        switch type {
        case .horn:
            print("blanking!")
            showOverlay(duration: 0.5, color: CGColor(gray: 1, alpha: 1))
            
            Spawner.shared.stop()
            Spawner.shared.clear()

            Spider.shared.stop()
            Spider.shared.moveOffscreen()
        case.freshener:
            print("swatting spider!")
            Spider.shared.stop()
            Spider.shared.moveOffscreen()
        case .drink:
            print("slowing down!")
        default:
            print("no effect")
        }
    }
   
    /// De-apply the powerup's effect
    func unsetEffect(for type: GameObjectType) {
        switch type {
        case .horn:
            print("resuming spawns!")
            Spawner.shared.start()
        case.freshener:
            print("spider active again!")
            Spider.shared.start()
        case .drink:
            print("restoring speed!")
        default:
            print("nothing to restore")
        }
    }
}
