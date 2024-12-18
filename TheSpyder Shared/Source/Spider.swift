import SpriteKit

class Spider {
    static let shared = Spider()
    
    private var targetScene: SKScene?
    
    private var entity: Entity?
    private var cageSprite: SKSpriteNode?
    private var arrowsSprite: SKSpriteNode?
    private var arrowsFrames: [SKTexture]?
    private var attackTimer: Timer?
    
    private let attackInterval: TimeInterval = 5
    private let peekDuration: TimeInterval = 3.0
    private let snatchDuration: TimeInterval = 0.5
    
    private var possibleAttackTargets: Array<CGPoint>?
    private var forbiddenPos: CGPoint?
    
    private let smoothTime = 7.5
    private var targetPos: CGPoint?
    
    private var isForbidden = false
    
    public func configure(scale: CGFloat, texture: SKTexture, cageTexture: SKTexture, arrowsFrames: [SKTexture], attackTargets: Array<CGPoint>, targetScene: SKScene){
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
        
        // Set up arrows
        self.arrowsFrames = arrowsFrames
        
        self.arrowsSprite = SKSpriteNode(texture: arrowsFrames.first)
        if let arrowsSprite = self.arrowsSprite {
            arrowsSprite.anchorPoint = CGPoint(x: 0.5, y: 0) // Easier to position using midbottom as reference
            arrowsSprite.isHidden = true
            arrowsSprite.setScale(scale * 0.8) // Make arrows slightly smaller to fit lane
            
            targetScene.addChild(arrowsSprite)
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
                let randomIndex = Int.random(in: 0..<attackTargets.count)
                let attackTarget = attackTargets[randomIndex]
                
                
                // Move to peek
                let moveToPeek = SKAction.run {
                    // Instantly move to that lane offscreen
                    if let entityFrameHeight = self.entity?.node.frame.height {
                        self.moveTo(position: CGPoint(x: attackTarget.x, y: -entityFrameHeight), teleport: true)
                    }
                    
                    self.moveTo(position: CGPoint(x: attackTarget.x, y: 0))
                    
                    if let scene = self.targetScene {
                        AudioHandler.shared.playSoundAsync("peek", target: scene)
                    }
                }
                
                // Show arrows
                let showArrows = SKAction.run {
                    self.showArrows(at: attackTarget)
                }
                
                // Stay peeked for a bit
                let stayPeeked = SKAction.wait(forDuration: peekDuration)
                
                // Hide arrows
                let hideArrows = SKAction.run {
                    self.hideArrows()
                }
                
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
                    // Return to same lane it came from in smooth motion
                    if let entityFrameHeight = self.entity?.node.frame.height {
                        self.moveTo(position: CGPoint(x: attackTarget.x, y: -entityFrameHeight), teleport: false)
                    }
                    
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
                    showArrows,
                    stayPeeked,
                    hideArrows,
                    snatch,
                    staySnatched,
                    moveBackDown,
                    restartTimer
                ]
                
                self.entity!.node.run(SKAction.sequence(sequence))
            }
        }
    }
    
    func showArrows(at attackTarget: CGPoint){
        if let arrowsSprite = self.arrowsSprite, let arrowsFrames = self.arrowsFrames, let spiderFrameHeight = self.entity?.node.frame.height {
            arrowsSprite.position.x = attackTarget.x
            arrowsSprite.position.y = 0 + spiderFrameHeight / 2
            
            arrowsSprite.isHidden = false
            
            let arrowsAnimation = SKAction.animate(with: arrowsFrames, timePerFrame: 1.0 / 4.0)
            arrowsSprite.run(SKAction.repeatForever(arrowsAnimation))
            
            print("showing arrows \(arrowsSprite.position.x), \(arrowsSprite.position.y)")
        }
    }
    
    func hideArrows(){
        if let arrowsSprite = self.arrowsSprite {
            arrowsSprite.isHidden = true
            arrowsSprite.removeAllActions()
        }
    }
    
    public func start(){
        print("restarting spider atk timer! interval: \(self.attackInterval)")
        
        // Run the timer; doesn't repeat because it restarts itself
        self.attackTimer = Timer.scheduledTimer(timeInterval: self.attackInterval, target: self, selector: #selector(self.attack), userInfo: nil, repeats: false)
    }
    
    public func stop(){
        // Hide indicator arrows
        self.hideArrows()
        
        if let entity = self.entity {
            // Remove any queued events
            entity.node.removeAllActions()
            
            // Stop the timer
            if self.attackTimer != nil {
                print("stopping spider timer...")
                
                self.attackTimer!.invalidate()
                self.attackTimer = nil
            }
        }
    }
    
    /// Freeze movement
    public func freeze(){
        if let entity = self.entity {
            entity.node.isPaused = true
        }
    }
    
    /// Unfreeze movement
    public func unfreeze(){
        if let entity = self.entity {
            entity.node.isPaused = false
        }
    }
    
    /// Forbids the spider from doing anything
    public func forbid(){
        if let destinationPos = forbiddenPos, let cageSprite = self.cageSprite, let node = self.entity?.node { // Abort attacks
            // State cannot be modified if frozen
            if node.isPaused {
                return
            }
            
            // Show forbid sprite
            cageSprite.isHidden = false
            
            // Hide indicator arrows
            self.hideArrows()
            
            // Cancel actions
            node.removeAllActions()
            
            // And stop timer
            if self.attackTimer != nil {
                print("stopping spider timer...")
                
                self.attackTimer!.invalidate()
                self.attackTimer = nil
            }
            
            // Move to spot
            
            // Move right below screen instantly TODO: Don't do this if already peeking
            if let entityFrameHeight = self.entity?.node.frame.height {
                self.moveTo(position: CGPoint(x: destinationPos.x, y: -entityFrameHeight), teleport: true)
            }
            
            // And start moving to the forbidden pos smoothly
            moveTo(position: destinationPos)
        }
    }
    
    /// Gives back the spider permission to attaclk
    public func unforbid(){
        if let cageSprite = self.cageSprite, let node = self.entity?.node {
            // State cannot be modified if frozen
            if node.isPaused {
                return
            }
            
            // Hide the cage sprite
            cageSprite.isHidden = true
            
            // Start action timer if inactive
            if self.attackTimer == nil {
                self.attackTimer = Timer.scheduledTimer(timeInterval: self.attackInterval, target: self, selector: #selector(self.attack), userInfo: nil, repeats: false)
            }
            
            // Move offscreen
            moveOffscreen(shouldDoInstantly: false)
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
        if let node = self.entity?.node, let targetPos = self.targetPos {
            if !node.isPaused {
                node.position.x = lerp(node.position.x, targetPos.x, smoothTime * deltaTime)
                node.position.y = lerp(node.position.y, targetPos.y, smoothTime * deltaTime)
            }
        }
        
        // Make cage stay on top of spider
        if let entity = self.entity {
            if let cage = self.cageSprite {
                cage.position = entity.node.position
            }
        }
        
    }
}
