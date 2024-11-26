import SpriteKit

class EffectHandler {
    static let shared = EffectHandler()

    let slowdownDuration = 5.0
    let spawnBlockDuration = 1.0
    
    var timer: Timer?

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
        case.freshener:
            print("swatting spider!")
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
        case.freshener:
            print("spider active again!")
        case .drink:
            print("restoring speed!")
        default:
            print("nothing to restore")
        }
    }
}
