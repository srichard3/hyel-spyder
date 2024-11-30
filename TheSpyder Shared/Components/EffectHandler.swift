import SpriteKit

class EffectHandler {
    static let shared = EffectHandler()

    let slowdownDuration = 5.0
    let slowdownSpeed = 500
    let lastSpeed = 0

    let spawnBlockDuration = 1.0

    var overlaySprite: SKSpriteNode?
    
    var timer: Timer?
    var lastEffector: GameObjectType? // Causer of the last effect

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
  
    /// Fade the overlay in
    func fadeInOverlay(transitionDuration: CGFloat, color: CGColor){
        if let overlaySprite = self.overlaySprite {
            // Set overlay color and ensure it's off
            overlaySprite.colorBlendFactor = 1
            overlaySprite.color = UIColor(cgColor: color)
            overlaySprite.alpha = 0

            // Run fade-in transition
            let fadeIn = SKAction.fadeAlpha(to: 1, duration: transitionDuration)
            overlaySprite.run(fadeIn)
        }
    }
 
    /// Fade the overlay out
    func fadeOutOverlay(transtionDuration: CGFloat){
        if let overlaySprite = self.overlaySprite {
            // Ensure overlay is on
            overlaySprite.alpha = 1
           
            // Run fade-out transition
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: transtionDuration)
            overlaySprite.run(fadeOut)
        }
    }
    
    /// Immediately turn on the overlay and fade it out over the given duration
    func flashOverlay(duration: CGFloat, color: CGColor){
        
        
        
        if let overlaySprite = self.overlaySprite {
            // Cancel other transition
            overlaySprite.removeAllActions()
            
            // Set overlay color and ensure it's on
            overlaySprite.colorBlendFactor = 1
            overlaySprite.color = UIColor(cgColor: color)
            overlaySprite.alpha = 1

            // Run fade-out transition
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: duration)
            overlaySprite.run(fadeOut)
        }
    }

    /// Begins run of a specified effect
    func runEffect(for type: GameObjectType){
        // If the new effector is same as last, invalidate timer; we want to restart that powerup's effect
        if type == lastEffector, let timer = self.timer {
            self.unsetEffect(for: type)
            timer.invalidate()
        }
        
        lastEffector = type
        
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
        setEffect(for: type, duration: selectedDuration)
       
        // Run the timer, unsetting the effect at completion
        timer = Timer.scheduledTimer(withTimeInterval: selectedDuration, repeats: false) { timer in
            self.unsetEffect(for: type)
            timer.invalidate()
        }
    }
   
    /// Apply the powerup's effect
    func setEffect(for type: GameObjectType, duration: CGFloat){
        switch type {
        case .horn:
            print("blanking!")
            // Flash white
            flashOverlay(duration: duration, color: CGColor(gray: 1, alpha: 1))
           
            // Stop spawning stuff for a bit
            Spawner.shared.stop()
            Spawner.shared.clear()

            // Swat the spider
            Spider.shared.stop()
            Spider.shared.moveOffscreen()
        case.freshener:
            print("swatting spider!")
            
            // Swat the spider
            Spider.shared.stop()
            Spider.shared.moveOffscreen()
        case .drink:
            print("slowing down!")
           
            // Start overlay
            fadeInOverlay(transitionDuration: 0.5, color: CGColor(red: 0, green: 0.25, blue: 0, alpha: 0.5))
            
            // Slow down
            SpeedKeeper.shared.startSpeedOverride(speed: slowdownSpeed)
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
            // Show overlay again
            fadeOutOverlay(transtionDuration: 0.5)
            
            // Restore speed
            SpeedKeeper.shared.stopSpeedOverride()
        default:
            print("nothing to restore")
        }
    }
}
