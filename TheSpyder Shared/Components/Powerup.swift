import SpriteKit

class Powerup{
    var entity: Entity
    var timer: Timer?
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(
            scale: scale,
            texture: texture,
            shadow: shadow,
            target: target,
            type: type,
            startPos: startPos
        )
        
        // Give initial velocity
        self.entity.node.physicsBody?.velocity = startVel
    }
   
    func runEffect(){
        // These are the durations of specific effects
        let slowdownDuration = 5.0
        let spawnBlockDuration = 1.0
       
        // This is the duration that our run of the next effect will have
        var selectedDuration: TimeInterval
      
        // Select it!
        switch self.entity.type {
        case .horn:
            selectedDuration = spawnBlockDuration
            return
        case .freshener:
            selectedDuration = 0
            return
        case .drink:
            selectedDuration = slowdownDuration
            return
        default:
            selectedDuration = 0
        }
       
        // Apply powerup effect
        setEffect()
        
        // Run the timer, unsetting the effect at completion
        timer = Timer.scheduledTimer(
            timeInterval: selectedDuration,
            target: self,
            selector: #selector(unsetEffect),
            userInfo: nil,
            repeats: false
        )
    }
   
    /// Apply the powerup's effect
    func setEffect(){
        switch self.entity.type {
        case .horn:
            return
        case.freshener:
            return
        case .drink:
            return
        default:
            return
        }
    }
   
    /// De-apply the powerup's effect
    @objc func unsetEffect() {
        switch self.entity.type {
        case .horn:
            return
        case.freshener:
            return
        case .drink:
            return
        default:
            return
        }
    }
}
