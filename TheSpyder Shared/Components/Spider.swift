import SpriteKit

class Spider{
    var entity: Entity
    var attackTimer: Timer! // We want this outside, since the spider needs externally passed info to reset its attack, but by design needs to be agnostic of its parent
    
    let attackInterval: TimeInterval = 5
    let peekDuration: TimeInterval = 3.0
    let snatchDuration: TimeInterval = 0.5
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.spider, startPos: startPos)
    }
   
    /// Run sequence of spider attack to a given point
    @objc func attack(at target: CGPoint){
        // TODO: Make the caller determine the target; pick random lane's x value
        // let chosenLaneX: CGFloat = playerLanes[Int.random(in: 0..<playerLanes.count)].x
        
        // Move to peek
        let moveToPeek = SKAction.run {
            self.entity.node.position.x = target.x
            self.entity.node.position.y = 0
        }
        
        // Stay peeked for a bit
        let stayPeeked = SKAction.wait(forDuration: peekDuration)
        
        // Then snatch!
        let snatch = SKAction.run {
            self.entity.node.position.x = target.x
            self.entity.node.position.y = target.y
        }
        
        // Stay in snatching position for a bit
        let staySnatched = SKAction.wait(forDuration: snatchDuration)
        
        // Move back down
        let moveBackDown = SKAction.run {
            self.entity.node.position.x = self.entity.node.parent == nil ? 0 : self.entity.node.parent!.frame.midX
            self.entity.node.position.y = -self.entity.node.frame.height
        }
    
        // Reinitialize timer
        /*
        let restartTimer = SKAction.run {
            attackTimer = Timer.scheduledTimer(withTimeInterval: attackInterval, repeats: true) { timer in
                timer.invalidate()
                self.attack()
            }
        }
         */
        
        // Run sequence
        let sequence = [
            moveToPeek,
            stayPeeked,
            snatch,
            staySnatched,
            moveBackDown,
            // restartTimer
        ]
        
        self.entity.node.run(SKAction.sequence(sequence))
    }
}
