import SpriteKit

class Spider {
    static let shared = Spider()

    private var targetScene: SKScene?
    
    private var entity: Entity?
    private var cageSprite: SKSpriteNode?
    private var attackTimer: Timer?
    
    private let attackInterval: TimeInterval = 5
    private let peekDuration: TimeInterval = 3.0
    private let snatchDuration: TimeInterval = 0.5
    
    private var possibleAttackTargets: Array<CGPoint>?
    private var forbiddenPos: CGPoint?

    private let smoothTime = 7.5
    private var targetPos: CGPoint?
   
    private var isFrozen = false
    private var isForbidden = false
    
    public func configure(scale: CGFloat, texture: SKTexture, cageTexture: SKTexture, attackTargets: Array<CGPoint>, targetScene: SKScene){
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
            
            // It should be hidden at start
            cage.isHidden = true
        }
        
        // Set lerp position to default
        self.targetPos = startPos
        
        // Set position to go to when forbidden to screen bottom just below player
        if let view = targetScene.view, let entity = self.entity {
            self.forbiddenPos = CGPoint(x: view.bounds.midX, y: 0 + entity.node.frame.height + 20)
        }
        
        // Assign attack targets
        self.possibleAttackTargets = attackTargets
        
        // Assign target scene
        self.targetScene = targetScene
    }
   
    /// Run sequence of spider attack to a given point
    @objc func attack(){
        print("trying to run spider attack...")
    
        if let attackTargets = possibleAttackTargets {
            if attackTargets.isEmpty {
                return
            }
            
            if targetPos != nil {
                print("attack will be run successfully!")
                
                // Pick random attack target
                let attackTarget = attackTargets[Int.random(in: 0..<attackTargets.count)]
                
                // Move to peek
                let moveToPeek = SKAction.run {
                    self.moveTo(position: CGPoint(x: attackTarget.x, y: 0))
                    
                    if let scene = self.targetScene {
                        AudioHandler.shared.playSoundAsync("peek", target: scene)
                    }
                }
                
                // Stay peeked for a bit
                let stayPeeked = SKAction.wait(forDuration: peekDuration)
                
                // Then snatch!
                let snatch = SKAction.run {
                    self.moveTo(position: CGPoint(x: attackTarget.x, y: attackTarget.y))
                    
                    if let scene = self.targetScene {
                        AudioHandler.shared.playSoundAsync("attack", target: scene)
                    }
                }
                
                // Stay in snatching position for a bit
                let staySnatched = SKAction.wait(forDuration: snatchDuration)
                
                // Move back down
                let moveBackDown = SKAction.run {
                    self.moveOffscreen()
                    
                    if let scene = self.targetScene {
                        AudioHandler.shared.playSoundAsync("hide", target: scene)
                    }
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
        }
    }
      
    public func start(){
        print("restarting spider atk timer! interval: \(self.attackInterval)")

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
  
    /// Forbids the spider from doing anything
    public func forbid(){
        if let destinationPos = forbiddenPos, let cageSprite = self.cageSprite {            // Abort attacks
            stop()
            
            // Move to the forbidden pos smoothly
            moveTo(position: destinationPos)
            
            // Show the cage sprite
            cageSprite.isHidden = false
        }
    }

    /// Gives back the spider permission to attaclk
    public func unforbid(){
        if let cageSprite = self.cageSprite {
            // Hide the cage sprite
            cageSprite.isHidden = true
            
            // Move offscreen
            moveOffscreen(shouldDoInstantly: false)
            
            // Resume attacks
            start()
        }
    }
   
    /// Teleport somewhere
    public func moveTo(position: CGPoint, teleport: Bool = false){
        if self.targetPos == nil {
            return
        }
       
        if self.entity == nil {
            return
        }
      
        self.targetPos!.x = position.x
        self.targetPos!.y = position.y
   
        // Set direct position as well if teleporting
        if teleport {
            self.entity!.node.position.x = self.targetPos!.x
            self.entity!.node.position.y = self.targetPos!.y
        }
    }
  
    /// Teleport offscreen
    public func moveOffscreen(shouldDoInstantly: Bool = false){
        if let entity = self.entity {
            moveTo(position: CGPoint(
                x: entity.node.parent == nil ? 0 : entity.node.parent!.frame.midX,
                y: -entity.node.frame.height
            ), teleport: shouldDoInstantly)
        }
    }

    public func update(with deltaTime: CGFloat){
        // Move using linear interpolation if unfrozen
        if !isFrozen {
            if let entity = self.entity, let targetPos = self.targetPos {
                entity.node.position.x = lerp(entity.node.position.x, targetPos.x, smoothTime * deltaTime)
                entity.node.position.y = lerp(entity.node.position.y, targetPos.y, smoothTime * deltaTime)
            }
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
