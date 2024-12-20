import SpriteKit

/// Keeps track of the game speed
class SpeedKeeper{
    static let shared = SpeedKeeper()

    var speed = 600
    var overriddenSpeed = 600
    var speedupAmount = 120
    var scoreUntilSpeedup = 50
    var scoreUntilSpeedupIncrement = 100

    private var lastSpeedBeforeFreeze = 0
    private var isFrozen = false
    private var isOverridden = false
  
    /// Set a speed value that overrides the current one, allowing a custom speed while the true one still updates in the background
    public func startSpeedOverride(speed: Int){
        isOverridden = true
        overriddenSpeed = speed
    }
   
    /// Unset the overridden state, returning normal speed
    public func stopSpeedOverride(){
        isOverridden = false
    }
 
    public func freeze(){
        isFrozen = true
    }
    
    public func unfreeze(){
        isFrozen = false
    }
    
    /// Get the speed to apply generally
    public func getSpeed() -> Int {
        if isFrozen {
            return 0
        } else if isOverridden {
            return overriddenSpeed
        } else {
            return speed
        }
    }
  
    /// Get speed to apply to cars
    public func getCarSpeed() -> Int {
        let carSpeedOffset = 30
        
        if isFrozen {
            return 0
        } else if isOverridden {
            return overriddenSpeed - carSpeedOffset
        } else {
            return speed - carSpeedOffset
        }
    }
    
    /// Update the speed based on given score
    public func update(){
        // If current score exceeds speedup threshold, increase game speed and score multiplier
        if ScoreKeeper.shared.score >= scoreUntilSpeedup {
            
            speed += speedupAmount
            scoreUntilSpeedup += scoreUntilSpeedupIncrement
            
            Spawner.shared.decrementSpawnInterval()
            
            ScoreKeeper.shared.multiplier += ScoreKeeper.shared.multiplierIncrement
        }
    }

    public func reset(){
        isOverridden = false
        
        speed = 600
        scoreUntilSpeedup = 50
        
        Spawner.shared.resetSpawnInterval()
    }
}
