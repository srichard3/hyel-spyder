import SpriteKit

class TSEffectKeeper {
    static let shared = TSEffectKeeper()

    /* Guaranteed Attributes */
    
    private var labelIsHidden = true
    private var targetLabelPos = CGPoint(x: 0, y: 0)

    private var activeEffectOverlays = Dictionary<TSGameObjectType, SKSpriteNode>()

    private let tooltips: Dictionary<TSGameObjectType, String> = [
        .freshener: "Spider Blocked",
        .drink: "Slowed Down"
        // No tooltip for horn since it flashes too quickly, but what the powerup does is pretty intuitive!
    ]

    private let overlayTints: Dictionary<TSGameObjectType, CGColor> = [
        .horn: CGColor(gray: 1, alpha: 1),
        .freshener: CGColor(red: 240 / 255, green: 53 / 255,  blue: 53 / 255 , alpha: 0.5),
        .drink: CGColor(red: 0.318, green: 0.694, blue: 0.427, alpha: 0.5)
    ]
    
    /* Unknown Attributes */
    
    private var targetScene: SKScene?
   
    private var overlayTexture: SKTexture?
    
    private var label: SKLabelNode?
    private var labelBg: [SKLabelNode]?
    
    private var timer: Timer?

    public func configure(overlay: SKTexture, labelFontName: String, targetScene: SKScene){
        // Feed overlay texture and target scene
        self.overlayTexture = overlay
        self.targetScene = targetScene

        // Set up label
        self.label = SKLabelNode()
        if let label = self.label {
            label.fontName = labelFontName
            label.fontColor = UIColor(cgColor: CGColor(red: 240 / 255, green: 189 / 255, blue: 22 / 255, alpha: 1))
            label.fontSize = 16
           
            // Set position based on score label
            label.position = CGPoint(x: 0, y: 0)
            if let scoreLabelPos = TSScoreKeeper.shared.getLabelPosition() {
                label.position = CGPoint(
                    x: scoreLabelPos.x,
                    y: scoreLabelPos.y - 40 // 30 is magic number
                )
            }
            
            label.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
           
            // Set target lerp pos from normal pos
            self.targetLabelPos = CGPoint(
                x: label.position.x,
                y: label.position.y
            )
            
            targetScene.addChild(label)
            
            print("made main fx label")

            // Now set up backing labels
            // Note that the position offsets will be applied in the lerp function
            if self.labelBg != nil {
                self.labelBg!.removeAll()
            } else {
                self.labelBg = []
            }
            
            for _ in 0..<4 {
                let newBgLabel = label.copy() as! SKLabelNode
              
                // They are all gray to give dark contrast
                newBgLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.1, alpha: 1))
                newBgLabel.zPosition -= 1
            
                targetScene.addChild(newBgLabel)

                self.labelBg!.append(newBgLabel)
            }
            
            print("have \(self.labelBg!.count) bg fx labels")
        } else {
            print("did not make main fx label")
        }
    }
   
    // Call these when we want the label instantly gone (game over screen, etc.)
    public func disableLabel(){
        if let label = self.label {
            label.isHidden = true
        }
      
        if let bgLabels = self.labelBg {
            for bgLabel in bgLabels {
                bgLabel.isHidden = true
            }
        }
    }
   
    public func enableLabel(){
        if let label = self.label {
            label.isHidden = false
        }
      
        if let bgLabels = self.labelBg {
            for bgLabel in bgLabels {
                bgLabel.isHidden = false
            }
        }
    }
    
    public func update(with deltaTime: CGFloat){
        // Lerp label to its pos, which is determined by its shown state
        if let label = self.label {
            if labelIsHidden {
                targetLabelPos.x = -label.frame.width
            } else if let targetSceneView = self.targetScene?.view {
                targetLabelPos.x = targetSceneView.frame.midX
            }
              
            // Move normal label
            label.position.x = TSMath.lerp(label.position.x, targetLabelPos.x, smoothTime * deltaTime)
            label.position.y = TSMath.lerp(label.position.y, targetLabelPos.y, smoothTime * deltaTime)
           
            // Move BG labels
            if let bgLabels = self.labelBg {
                let offset = label.fontSize / 6

                // First make their position match the main label's
                for bgLabel in bgLabels {
                    bgLabel.position.x = label.position.x
                    bgLabel.position.y = label.position.y
                }
               
                // And then apply directional offset to each
                bgLabels[0].position.x += offset
                bgLabels[1].position.x -= offset
                bgLabels[2].position.y += offset
                bgLabels[3].position.y -= offset
            }
        }
    }
    
    private func updateIndicatorLabel(){
        if let label = self.label {
            // Should only update label if effects are left
            if !self.activeEffectOverlays.isEmpty {
                // Ensure label is shown
                labelIsHidden = false
                
                // Get array of active effects as it is at call-time
                let activeEffectsAsArray = Array(activeEffectOverlays.keys)
                
                // Build tooltip string based on state of this array
                var labelText = ""
                for i in 0..<activeEffectsAsArray.count {
                    // Update text if there's a tooltip for this effect
                    if let tooltipForActiveEffect = tooltips[activeEffectsAsArray[i]] {
                        // Add a plus after the current effect text being processed if it isn't the last one
                        if i < activeEffectsAsArray.count - 1 {
                            labelText += "\(tooltipForActiveEffect) + "
                        // Otherwise, just add the text and nothing after it
                        } else {
                            labelText += "\(tooltipForActiveEffect)!"
                        }
                    }
                }
                
                // The resulting text should look like "PowerUp1 + PowerUp2" instead of "PowerUp! + PowerUp2 + "
                
                // Note we need to update both fg label and bg labels
                label.text = labelText
               
                if let bgLabels = self.labelBg {
                    for bgLabel in bgLabels {
                        bgLabel.text = labelText
                    }
                }
            // If no effects, hide the label; don't update the text since we'd just hide it if we did that
            } else {
                labelIsHidden = true
            }
        }
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
            
            // It should also be right above the background
            // It looks cooler when overlay only affects road :)
            overlaySprite.zPosition = CGFloat(TSGameObjectType.background.rawValue) + 1
            
            // Add to scene
            scene.addChild(overlaySprite)
            
            return overlaySprite
        }
        
        return nil
    }
   
    /// Show an overlay for a specific duration, with fade-in and fade-out
    public func beginEffect(for type: TSGameObjectType){
        // If the passed effect is already running, re-run it
        // The easiest way to do this is just to restart the effect altogether
        if activeEffectOverlays.keys.contains(type) {
            restartEffect(type)
            return
        }
       
        // Decide overlay color
        let color = overlayTints[type]!

        if let overlaySprite = spawnOverlay(color: color) {
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
                    return TSSpider.shared.getAttackInterval() / 2
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
                SKAction.run {
                    // Add overlay to overlays
                    self.activeEffectOverlays[type] = overlaySprite
                   
                    // Set the effect
                    self.setEffect(for: type)
                },
                SKAction.fadeAlpha(to: color.alpha, duration: fadeInDuration),
                SKAction.wait(forDuration: stayDuration),
                SKAction.run {
                    // Remove from overlays array
                    self.activeEffectOverlays.removeValue(forKey: type)
                    
                    // Unset the effect
                    self.unsetEffect(for: type)
                },
                SKAction.fadeAlpha(to: 0, duration: fadeOutDuration),
                SKAction.removeFromParent(),
            ])
            
            overlaySprite.run(sequence)
        }
    }
   
    /// Apply the powerup's effect
    private func setEffect(for type: TSGameObjectType){
        // Set the actual effect
        switch type {
        case .horn:
            print("blanking!")

            // Stop spawning stuff for a bit
            TSSpawnKeeper.shared.stopTimer()
            TSSpawnKeeper.shared.clearCars()
        case.freshener:
            print("forbidding spider!")
            
            // Forbid the spider
            TSSpider.shared.forbid()
        case .drink:
            print("slowing down!")
            
            // Slow down
            TSSpeedKeeper.shared.startSpeedOverride(speed: 400)
        default:
            print("no effect")
        }
        
        // Update the indicator label
        updateIndicatorLabel()
    }
   
    /// De-apply the powerup's effect
    private func unsetEffect(for type: TSGameObjectType) {
        switch type {
        case .horn:
            print("resuming spawns!")
            
            // Allow new spawns
            TSSpawnKeeper.shared.startTimer()
        case.freshener:
            print("spider active again!")
            
            // Spider can attack again
            TSSpider.shared.unforbid()
        case .drink:
            print("restoring speed!")
            
            // Restore old speed
            TSSpeedKeeper.shared.stopSpeedOverride()
        default:
            print("nothing to restore")
        }
        
        // Update the indicator label
        updateIndicatorLabel()
    }
   
    public func pauseAll(){
        for overlay in activeEffectOverlays.values {
            overlay.isPaused = true
        }
    }
    
    public func resumeAll(){
        for overlay in activeEffectOverlays.values {
            overlay.isPaused = false
        }
    }

    public func removeEffect(_ effect: TSGameObjectType){
        // Remove effect overlay
        if  let removedEffect = activeEffectOverlays.removeValue(forKey: effect) {
            removedEffect.removeAllActions()
            removedEffect.removeFromParent()
        }
           
        // Update label
        updateIndicatorLabel();
    }
   
    public func restartEffect(_ effect: TSGameObjectType) {
        if let activeOverlay = self.activeEffectOverlays[effect] {
            // Remove remaining actions for this effect
            activeOverlay.removeAllActions()
            
            // Decide durations
            // MARK: Move to shorthand function?
            let fadeOutDuration = {
                switch effect {
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
                switch effect {
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

            // Only add second half of action sequence, i.e. exclude the effect-setting part and start from the wait
            // This effectively re-starts the effect without re-adding it
            let sequence = SKAction.sequence([
                SKAction.wait(forDuration: stayDuration),
                SKAction.run {
                    // Remove from overlays array
                    self.activeEffectOverlays.removeValue(forKey: effect)
                    
                    // Unset the effect
                    self.unsetEffect(for: effect)
                },
                SKAction.fadeAlpha(to: 0, duration: fadeOutDuration),
                SKAction.removeFromParent(),
            ])
            
            activeOverlay.run(sequence)
        }
    }
    
    public func clearAll(){
        // Remove all overlay entries
        for overlay in activeEffectOverlays.values {
            overlay.removeAllActions()
            overlay.removeFromParent()
        }
        
        activeEffectOverlays.removeAll()
            
        // Update label
        updateIndicatorLabel()
    }
}
