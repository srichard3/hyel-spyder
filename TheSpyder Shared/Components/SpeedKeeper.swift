import SpriteKit

/// Keeps track of the game speed
class SpeedKeeper{
    static let shared = SpeedKeeper()

    var speed: CGFloat = 600
    var speedupAmount: CGFloat = 120
    var scoreUntilSpeedup: Int = 50
    var scoreUntilSpeedupIncrement: Int = 100
    
    /// Update the speed based on given score
    public func update(){
        // If current score exceeds speedup threshold, increase game speed and score multiplier
        if ScoreKeeper.shared.score >= scoreUntilSpeedup {
            speed += speedupAmount
            scoreUntilSpeedup += scoreUntilSpeedupIncrement
            ScoreKeeper.shared.multiplier += ScoreKeeper.shared.multiplierIncrement
            CarSpawner.shared.carSpeed = SpeedKeeper.shared.speed - 30
            CarSpawner.shared.spawnInterval -= CarSpawner.shared.spawnIntervalDecrement
        }
    }
    
    public func freeze(){
        // Make all speed 0; will we ever need to unfreeze?
        speed = 0
        CarSpawner.shared.carSpeed = 0
    }
}
