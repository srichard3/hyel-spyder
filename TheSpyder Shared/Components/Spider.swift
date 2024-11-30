import SpriteKit

class Spider {
    static let shared = Spider()
    
    var entity: Entity?
    var cageSprite: SKSpriteNode?
    var attackTimer: Timer?
    
    let attackInterval: TimeInterval = 5
    let peekDuration: TimeInterval = 3.0
    let snatchDuration: TimeInterval = 0.5
    
    var possibleAttackTargets = Array<CGPoint>()

    let smoothTime = 7.5
    var targetPos: CGPoint?
   
    var isFrozen = false
    
    public func configure(scale: CGFloat, texture: SKTexture, cageTexture: SKTexture, targetScene: SKScene){
        // Start spider offscreen
        let startPos = CGPoint(x: 0, y: -texture.size().height * scale)
        
        // Set up entity
        self.entity = Entity(
            scale: scale,
            texture: texture,
            shadow: nil,
            target: targetScene,
            type: GameObjectType.spider,
            startPos: startPos
        )
      
        // Set up cage
        cageSprite = SKSpriteNode(texture: cageTexture)
        
        if let cage = cageSprite, let entity = self.entity {
            targetScene.addChild(cage)
           
            // Make cage slightly bigger so spider fits
            cage.setScale(scale + 1)
            
            // Ensure it's on top of spider
            cage.zPosition = entity.node.zPosition + 1
        }
        
        // Set lerp position to default
        self.targetPos = startPos
    }
   
    /// Run sequence of spider attack to a given point
    @objc func attack(){
        if possibleAttackTargets.isEmpty {
            return
        }
       
        if self.targetPos == nil {
            return
        }
        
        if self.entity == nil {
            return
        }
      
        // Pick random attack target
        let attackTarget = possibleAttackTargets[Int.random(in: 0..<possibleAttackTargets.count)]
        
        // Move to peek
        let moveToPeek = SKAction.run {
            self.targetPos!.x = attackTarget.x
            self.targetPos!.y = 0
        }
        
        // Stay peeked for a bit
        let stayPeeked = SKAction.wait(forDuration: peekDuration)
        
        // Then snatch!
        let snatch = SKAction.run {
            self.targetPos!.x = attackTarget.x
            self.targetPos!.y = attackTarget.y
        }
        
        // Stay in snatching position for a bit
        let staySnatched = SKAction.wait(forDuration: snatchDuration)
        
        // Move back down
        let moveBackDown = SKAction.run {
            self.targetPos!.x = self.entity!.node.parent == nil ? 0 : self.entity!.node.parent!.frame.midX
            self.targetPos!.y = -self.entity!.node.frame.height
        }
   
        // Start the timer again
        let restartTimer = SKAction.run {
            self.attackTimer = Timer.scheduledTimer(withTimeInterval: self.attackInterval, repeats: false) { timer in
                timer.invalidate()
                self.attack()
            }
        }
        
        // Run sequence
        let sequence = [
            moveToPeek,
            stayPeeked,
            snatch,
            staySnatched,
            moveBackDown,
            restartTimer
        ]
        
        self.entity!.node.run(SKAction.sequence(sequence))
    }
      
    /// Make the spider move towards its target position using lerp
    private func lerpMove(with deltaTime: CGFloat){
        if let entity = self.entity, let targetPos = self.targetPos {
            entity.node.position.x = lerp(entity.node.position.x, targetPos.x, smoothTime * deltaTime)
            entity.node.position.y = lerp(entity.node.position.y, targetPos.y, smoothTime * deltaTime)
        }
    }

    public func start(){
        // Run the timer; doesn't repeat because it restarts itself
        self.attackTimer = Timer.scheduledTimer(timeInterval: self.attackInterval, target: self, selector: #selector(self.attack), userInfo: nil, repeats: false)
    }
  
    public func stop(){
        if let entity = self.entity {
            // Remove any queued events
            entity.node.removeAllActions()
           
            // Stop the timer
            if self.attackTimer != nil {
                self.attackTimer!.invalidate()
                self.attackTimer = nil
            }
        }
    }
 
    /// Freeze movement
    public func freeze(){
        // Don't re-run already set state transition
        if isFrozen {
            return
        }
        
        // Set frozen state
        if let entity = self.entity {
            entity.node.isPaused = true
            
            isFrozen = true
        }
    }
  
    /// Unfreeze movement
    public func unfreeze(){
        // Don't re-run already set state transition
        if !isFrozen {
            return
        }

        if let entity = self.entity {
            entity.node.isPaused = false
            
            isFrozen = false
        }
    }
    
    public func moveOffscreen(){
        if self.targetPos == nil {
            return
        }
       
        if self.entity == nil {
            return
        }
       
        // Teleport spider offscreen by immediately setting both real pos (node pos) and target pos
        self.targetPos!.x = self.entity!.node.parent == nil ? 0 : self.entity!.node.parent!.frame.midX
        self.targetPos!.y = -self.entity!.node.frame.height

        self.entity!.node.position.x = self.targetPos!.x
        self.entity!.node.position.y = self.targetPos!.y
    }
    
    public func update(with deltaTime: CGFloat){
        if !isFrozen {
            lerpMove(with: deltaTime)
        }
       
        if let entity = self.entity {
            // Update entity
            entity.update()
           
            // Make cage stay on top of spider
            if let cage = self.cageSprite {
                cage.position = entity.node.position
            }
        }
        
    }
}
