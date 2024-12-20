import SpriteKit

/// Keeps track of the game speed
class TSSpeedKeeper{
    static let shared = TSSpeedKeeper()

    private let baseSpeed = 600
    private var speed = 600 // Should match base value!

    private var overriddenSpeed = 600 // Should initially match base speed!
    
    private let speedupAmount = 120
   
    private var scoreUntilSpeedup = 50 // Should match base score gain until speedup value!
    
    private let baseScoreGainUntilSpeedup = 50
    private let scoreGainUntilSpeedupIncrement = 50

    private var lastSpeedBeforeFreeze = 0
    
    private var isFrozen = false
    private var isOverridden = false
  
    /// Set a speed value that overrides the current one, allowing a custom speed while the true one still updates in the background
    public func startSpeedOverride(speed: Int){
        if self.isOverridden {
            return
        }
        
        self.isOverridden = true
        self.overriddenSpeed = speed
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
        if TSScoreKeeper.shared.getCurrentScore() >= scoreUntilSpeedup {
            self.speed += self.speedupAmount
            self.scoreUntilSpeedup += self.scoreGainUntilSpeedupIncrement
            
            TSSpawnKeeper.shared.subdivideSpawnInterval()
            
            TSScoreKeeper.shared.incrementScoreMultiplier()
        }
    }

    public func clearState(){
        stopSpeedOverride()
   
        self.overriddenSpeed = self.baseSpeed
        self.speed = self.baseSpeed
        self.scoreUntilSpeedup = self.baseScoreGainUntilSpeedup
        
        TSSpawnKeeper.shared.resetSpawnInterval()
    }
}
