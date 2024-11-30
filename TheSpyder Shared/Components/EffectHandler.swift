import SpriteKit

class EffectHandler {
    static let shared = EffectHandler()

    var targetScene: SKScene?
    var overlayTexture: SKTexture?
    var timer: Timer?
    var activeEffects = Set<GameObjectType>()
    var activeEffectOverlays = Array<SKSpriteNode>()

    public func configure(overlay: SKTexture, targetScene: SKScene){
        self.overlayTexture = overlay
        self.targetScene = targetScene
    }
 
    private func spawnOverlay(color: CGColor) -> SKSpriteNode? {
        // Make the overlay sprite cover the entire screen
        if let scene = self.targetScene, let view = scene.view {
            // Make new overlay
            let overlaySprite = SKSpriteNode(texture: self.overlayTexture)
           
            overlaySprite.colorBlendFactor = 1
            overlaySprite.color = UIColor(cgColor: color)

            // Make it fill screen
            overlaySprite.position.x = view.frame.midX
            overlaySprite.position.y = view.frame.midY
            
            overlaySprite.size.width = view.frame.width
            overlaySprite.size.height = view.frame.height
            
            // It should also be on top of everything
            overlaySprite.zPosition = 999
            
            // Add to scene
            scene.addChild(overlaySprite)
            
            return overlaySprite
        }
        
        return nil
    }
   
    /// Show an overlay for a specific duration, with fade-in and fade-out
    func runEffect(for type: GameObjectType){
        // If the passed effect is already running, avoid re-running it
        if activeEffects.contains(type) {
            return
        }
       
        activeEffects.insert(type)
        
        // Decide overlay color
        let color: CGColor = {
            switch type {
            case .freshener:
                return CGColor(red: 0.306, green: 0.459, blue: 0.498, alpha: 0.5)
            case .horn:
                return CGColor(gray: 1, alpha: 1)
            case .drink:
                return CGColor(red: 0.318, green: 0.694, blue: 0.427, alpha: 0.5)
            default:
                return CGColor(gray: 1, alpha: 1)
            }
        }()

        if let overlaySprite = spawnOverlay(color: color) {
            // Add overlay to overlays
            activeEffectOverlays.append(overlaySprite)

            // Decide durations for everything
            let fadeInDuration = {
                switch type {
                case .freshener:
                    return 0.25
                case .horn:
                    return 0
                case .drink:
                    return 0.25
                default:
                    return 0
                }
            }()

            let fadeOutDuration = {
                switch type {
                case .freshener:
                    return 0.25
                case .horn:
                    return 1
                case .drink:
                    return 0.25
                default:
                    return 0
                }
            }()

            let stayDuration: TimeInterval = {
                switch type {
                case .freshener:
                    return 10
                case .horn:
                    return 0
                case .drink:
                    return 5
                default:
                    return 0
                }
            }()

            // Start from fully invisible state, since we will be fading in
            overlaySprite.alpha = 0
            
            // Run entire effect sequence
            let sequence = SKAction.sequence([
                SKAction.fadeAlpha(to: color.alpha, duration: fadeInDuration),
                SKAction.run {self.setEffect(for: type)},
                SKAction.wait(forDuration: stayDuration),
                SKAction.run {self.unsetEffect(for: type)},
                SKAction.fadeAlpha(to: 0, duration: fadeOutDuration),
                SKAction.run {
                    // Remove active effect entry
                    self.activeEffects.remove(type)
                },
                SKAction.removeFromParent(),
                SKAction.run {
                    // Remove from overlays array
                    if let overlaySpriteIndex = self.activeEffectOverlays.firstIndex(of: overlaySprite) {
                        self.activeEffectOverlays.remove(at: overlaySpriteIndex)
                    }
                }
            ])
            
            overlaySprite.run(sequence)
        }
    }
   
    /// Apply the powerup's effect
    func setEffect(for type: GameObjectType){
        switch type {
        case .horn:
            print("blanking!")

            // Stop spawning stuff for a bit
            Spawner.shared.stop()
            Spawner.shared.clearCars()

            // Swat the spider
            Spider.shared.stop()
        case.freshener:
            print("forbidding spider!")
            
            // Forbidthe spider
            Spider.shared.forbid()
        case .drink:
            print("slowing down!")
            
            // Slow down
            SpeedKeeper.shared.startSpeedOverride(speed: 400)
        default:
            print("no effect")
        }
    }
   
    /// De-apply the powerup's effect
    func unsetEffect(for type: GameObjectType) {
        switch type {
        case .horn:
            print("resuming spawns!")
            
            // Allow new spawns
            Spawner.shared.start()
            Spider.shared.start()
        case.freshener:
            print("spider active again!")
            
            // Spider can attack again
            Spider.shared.unforbid()
        case .drink:
            print("restoring speed!")
            
            // Restore old speed
            SpeedKeeper.shared.stopSpeedOverride()
        default:
            print("nothing to restore")
        }
    }
   
    func pauseAll(){
        for overlay in activeEffectOverlays {
            overlay.isPaused = true
        }
    }
    
    func unpauseAll(){
        for overlay in activeEffectOverlays {
            overlay.isPaused = false
        }
    }

    func cleanup(){
        // Remove all active effects
        activeEffects.removeAll()
        
        // Remove all overlay entries
        for overlay in activeEffectOverlays {
            overlay.removeAllActions()
            overlay.removeFromParent()
        }
        
        activeEffectOverlays.removeAll()
    }
}
