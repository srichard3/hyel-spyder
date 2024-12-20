import SpriteKit

class TSSpider {
    static let shared = TSSpider()
    
    /* Guaranteed Attributes */
    
    private let attackInterval: TimeInterval = 5
    private let peekDuration: TimeInterval = 3.0
    private let snatchDuration: TimeInterval = 0.5

    private var forbiddenPos = CGPoint(x: 0, y: 0)
    private var targetPos = CGPoint(x: 0, y: 0)

    private var isForbidden = false

    /* Nullable Attributes */
   
    private var targetScene: SKScene?

    private var entity: TSEntity?

    private var cageSprite: SKSpriteNode?
    
    private var arrowsSprite: SKSpriteNode?
    private var arrowsFrames: [SKTexture]?
    
    private var attackTimer: Timer?
    
    private var possibleAttackTargets: Array<CGPoint>?
    
    public func getNode() -> SKSpriteNode? {
        return self.entity?.getNode()
    }
   
    public func getAttackInterval() -> CGFloat {
        return self.attackInterval
    }
    
    public func configure(scale: CGFloat, texture: SKTexture, cageTexture: SKTexture, arrowsFrames: [SKTexture], attackTargets: Array<CGPoint>, targetScene: SKScene){
        // Start spider offscreen
        let startPos = CGPoint(x: 0, y: -texture.size().height * scale)

        // Set up entity
        self.entity = TSEntity(
            scale: scale,
            texture: texture,
            shadow: nil,
            target: targetScene,
            type: TSGameObjectType.spider,
            startPos: startPos
        )
    
        // Set up cage
        cageSprite = SKSpriteNode(texture: cageTexture)
        
        if let cage = cageSprite {
            targetScene.addChild(cage)
            
            // Make cage slightly bigger so spider fits
            cage.setScale(scale + 1)
            
            // Ensure it's on top of spider
            cage.zPosition = getNode()!.zPosition + 1
            
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
        
        // Set lerp position to match starting pos
        self.targetPos = startPos
        
        // Set position to go to when forbidden to screen bottom just below player
        if let view = targetScene.view {
            self.forbiddenPos = CGPoint(x: view.bounds.midX, y: 0 + getNode()!.frame.height + 20)
        }
        
        // Assign attack targets
        self.possibleAttackTargets = attackTargets
        
        // Assign target scene
        self.targetScene = targetScene
    }
    
    public func update(with deltaTime: CGFloat){
        // Cannot modify state if frozen
        if let node = self.getNode(), node.isPaused == false {
            // Move using linear interpolation if unfrozen
            if !node.isPaused {
                node.position.x = TSMath.lerp(node.position.x, targetPos.x, smoothTime * deltaTime)
                node.position.y = TSMath.lerp(node.position.y, targetPos.y, smoothTime * deltaTime)
            }

            // Make cage stay on top of spider
            if let cage = self.cageSprite {
                cage.position = getNode()!.position
            }
        }
    }

    private func showArrows(at attackTarget: CGPoint){
        // Cannot modify state if frozen
        if let arrowsSprite = self.arrowsSprite, let arrowsFrames = self.arrowsFrames, let node = self.getNode(), node.isPaused == false {
            let spiderFrameHeight = node.frame.height
            
            arrowsSprite.position.x = attackTarget.x
            arrowsSprite.position.y = 0 + spiderFrameHeight / 2
            
            arrowsSprite.isHidden = false
            
            let arrowsAnimation = SKAction.animate(with: arrowsFrames, timePerFrame: 1.0 / 4.0)
            
            arrowsSprite.run(SKAction.repeatForever(arrowsAnimation))
            
            print("showing spider preview arrows")
        }
    }
    
    private func hideArrows(){
        // Cannot modify state if paused
        if let node = self.getNode(), node.isPaused == true {
            return
        }
        
        if let arrowsSprite = self.arrowsSprite {
            arrowsSprite.removeAllActions()
            
            arrowsSprite.isHidden = true
            
            print("hiding spider preview arrows")
        }
    }
   
    @objc private func attack(){
        if let attackTargets = possibleAttackTargets, attackTargets.isEmpty == false, let node = self.getNode(), node.isPaused == false {
            print("charging spider attack...")

            // Pick random attack target
            let randomIndex = Int.random(in: 0..<attackTargets.count)
            let attackTarget = attackTargets[randomIndex]
            
            // Move to peek
            let moveToPeek = SKAction.run {
                let entityFrameHeight = node.frame.height
               
                // Instantly move to lane we will peek out from, offscreen
                self.moveTo(position: CGPoint(x: attackTarget.x, y: -entityFrameHeight), teleport: true)
                
                // Then smoothly move to peek position!
                self.moveTo(position: CGPoint(x: attackTarget.x, y: 0), teleport: false)
                
                if let scene = self.targetScene {
                    TSAudioKeeper.shared.playSoundAsync("peek", target: scene)
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
                    TSAudioKeeper.shared.playSoundAsync("attack", target: scene)
                }
            }
            
            // Stay in snatching position for a bit
            let staySnatched = SKAction.wait(forDuration: snatchDuration)
            
            // Move back down
            let moveBackDown = SKAction.run {
                let entityFrameHeight = node.frame.height
               
                // Return to same lane we came from in smooth motion
                self.moveTo(position: CGPoint(x: attackTarget.x, y: -entityFrameHeight), teleport: false)
              
                if let scene = self.targetScene {
                    TSAudioKeeper.shared.playSoundAsync("hide", target: scene)
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
           
            print("built spider attack sequence")
            
            node.run(SKAction.sequence(sequence))
            
            print("ran spider attack sequence")
        }
    }
    
    public func start(){
        // Cannot modify state if paused
        if let node = self.getNode(), node.isPaused == true {
            return
        }
        
        // Run the timer if not on already; should be restarted manually!
        if self.attackTimer == nil {
            self.attackTimer = Timer.scheduledTimer(
                timeInterval: self.attackInterval,
                target: self,
                selector: #selector(self.attack),
                userInfo: nil,
                repeats: false
            )
            
            print("restarting spider atk timer! interval: \(self.attackInterval)")
        }
    }
    
    public func clearState(){
        // Cannot modify state if paused
        if let node = self.getNode(), node.isPaused == true {
            return
        }
        
        // Hide indicator arrows
        self.hideArrows()
   
        // Stop the timer
        if self.attackTimer != nil {
            print("stopping spider atk timer...")
            
            self.attackTimer!.invalidate()
            self.attackTimer = nil
        }
        
        // Remove any queued events
        if let node = self.getNode() {
            node.removeAllActions()
        }
        
        // Hide forbid sign (forbidden state is cleared)
        if let forbidSign = self.cageSprite {
            forbidSign.isHidden = true
        }
        
        // Move offscreen
        self.moveOffscreen(shouldDoInstantly: true)
    }
    
    public func freeze(){
        if let node = self.getNode() {
            node.isPaused = true
        }
    }
    
    public func unfreeze(){
        if let node = self.getNode() {
            node.isPaused = false
        }
        
        // Start timer again if there isn't one...
        self.start()
    }
    
    public func forbid(){
        // Cannot modify state if paused
        if let node = self.getNode(), node.isPaused == false {
            // Remove all node actions
            node.removeAllActions()
            
            let spiderFrameHeight = node.frame.height
            
            // Move to forbidden lane instantly, offscreen
            self.moveTo(position: CGPoint(x: forbiddenPos.x, y: -spiderFrameHeight), teleport: true)
           
            // Then move to peek pos smoothly
            self.moveTo(position: CGPoint(x: forbiddenPos.x, y: forbiddenPos.y))
        }
        
        // Hide indicator arrows
        self.hideArrows()

        // Stop/cancel attack timer
        if self.attackTimer != nil {
            self.attackTimer!.invalidate()
            self.attackTimer = nil
            
            print("stopped spider atk timer...")
        }

        if let forbidSign = self.cageSprite {
            // Show forbid sign
            forbidSign.isHidden = false
        }
    }
    
    public func unforbid(){
        // Don't allow modifying state if paused
        if let node = self.getNode(), node.isPaused == true {
            return
        }
        
        // Move offscreen
        self.moveOffscreen(shouldDoInstantly: false)

        // Try start action timer if inactive
        self.start()
        
        if let forbidSign = self.cageSprite {
            // Hide the cage sprite
            forbidSign.isHidden = true
        }
    }
    
    public func moveTo(position: CGPoint, teleport: Bool = false){
        // Don't allow modifying state if paused
        if let node = self.getNode(), node.isPaused == true {
            return
        }
        
        // Update lerp target position
        self.targetPos.x = position.x
        self.targetPos.y = position.y
       
        // Also update direct position if we want movement to be instant
        if teleport == true, let node = self.getNode() {
            node.position.x = self.targetPos.x
            node.position.y = self.targetPos.y
        }
    }
    
    public func moveOffscreen(shouldDoInstantly: Bool = false){
        // Move to offscreen pos
        if let node = self.getNode(), node.isPaused == false {
            let xDest = node.parent == nil ? 0 : node.parent!.frame.midX
            
            moveTo(position: CGPoint(
                x: xDest,
                y: -node.frame.height
            ), teleport: shouldDoInstantly)
        }
    }
}
