import SpriteKit

class TSGameScene: SKScene, SKPhysicsContactDelegate {
    //
    
    weak var context: TSGameContext?
   
    //

    private var gameIsPaused = false
    
    private var gameState: TTGameState?
    private var lastGameState: TTGameState?

    private var globalScale: CGFloat = 1

    private var lastUpdateTime: TimeInterval = 0

    private var deltaTime: CGFloat = 0

    let textures = [
        "blank" : SKTexture(imageNamed: "blank"),
        "cage" : SKTexture(imageNamed: "cage"),
        "forbidden" : SKTexture(imageNamed: "forbidden"),
        "background" : SKTexture(imageNamed: "road"),
        "title" : SKTexture(imageNamed: "logo"),
        "game_over" : SKTexture(imageNamed: "game_over"),
        "player" : SKTexture(imageNamed: "player"),
        "spider" : SKTexture(imageNamed: "spider"),
        "shadow" : SKTexture(imageNamed: "shadow"),
        "horn" : SKTexture(imageNamed: "honk"),
        "drink" : SKTexture(imageNamed: "drink"),
        "freshener" : SKTexture(imageNamed: "freshener"),
        "car_green" : SKTexture(imageNamed: "car_g"),
        "car_orange" : SKTexture(imageNamed: "car_o"),
        "car_red" : SKTexture(imageNamed: "car_r"),
        "car_yellow" : SKTexture(imageNamed: "car_y"),
        "arrows_0" : SKTexture(imageNamed: "arrows_0"),
        "arrows_1" : SKTexture(imageNamed: "arrows_1"),
        "arrows_2" : SKTexture(imageNamed: "arrows_2"),
        "arrows_3" : SKTexture(imageNamed: "arrows_3")
    ]
  
    var backgroundA: SKSpriteNode?
    var backgroundB: SKSpriteNode?
    var backgroundC: SKSpriteNode?
    var backgroundD: SKSpriteNode?
    
    var titleCard: SKSpriteNode?
    var gameOverCard: SKSpriteNode?
    var beginLabel: SKLabelNode?
    
    var player: TSPlayer?
   
    var swipeLeft: UISwipeGestureRecognizer?
    var swipeRight: UISwipeGestureRecognizer?
    var tap: UITapGestureRecognizer?
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    //
    
    init(context: TSGameContext, size: CGSize){
        self.context = context
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    func prepareGameContext(){
        guard let context else {
            return
        }
        
        context.scene = self
    }
    
    //
    
    private func setGlobalScale(from view: SKView){
        // Fill the screen regardless of anything
        self.scaleMode = .aspectFill
        
        // The global scale is based on how much we need to scale the background by to cover the whole scene's frame
        let xScaleFactor = view.frame.width / textures["background"]!.size().width
        let yScaleFactor = view.frame.height / textures["background"]!.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
    }
   
    private func configurePhysics(){
        self.physicsWorld.contactDelegate = self // Make contact tests take place in this scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Remove gravity
    }
   
    /// Sets up left, right, and tap gesture recognizers
    private func configureGestureRecognizers(using view: SKView){
        self.swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))) // The _: effectively makes it so the recognizer passes itself into HandleSwipe
        if let swipeLeft = self.swipeLeft {
            swipeLeft.direction = .left
            view.addGestureRecognizer(swipeLeft)
        }
        
        
        self.swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        if let swipeRight = self.swipeRight {
            swipeRight.direction = .right
            view.addGestureRecognizer(swipeRight)

        }

        self.tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        if let tap = self.tap {
            view.addGestureRecognizer(tap)
        }
    }
   
    /// Make textures all resize as nearest neighbor
    private func configureTextures(){
        for texture in textures.values {
            texture.filteringMode = .nearest
        }
    }
   
    private func configureGUIElements(using view: SKView){
        // Setup title card
        let titleCardScale = 0.2
        
        self.titleCard = SKSpriteNode(texture: textures["title"]!)
        if let titleCard = self.titleCard {
            titleCard.setScale(globalScale * titleCardScale)
            titleCard.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
            titleCard.position = CGPoint(
                x: view.frame.midX,
                y: view.frame.midY + titleCard.frame.height / 2
            )
            
            addChild(titleCard)
        }
        
        // Set up begin label
        var beginLabelYPos: CGFloat
      
        // Begin label offset is midpoint between player frame top and title card bottom
        if let playerFrame = self.player?.getNode().frame, let titleCardFrame = self.titleCard?.frame {
            beginLabelYPos = playerFrame.maxY + (titleCardFrame.minY - playerFrame.maxY) / 2.0
        } else {
            beginLabelYPos = frame.midY // Fall back to screen center
        }
        
        self.beginLabel = SKLabelNode(text: "Swipe to Begin!")
        if let beginLabel = self.beginLabel {
            beginLabel.fontName = "FFF Forward"
            beginLabel.fontSize = 16
            beginLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.8, alpha: 1))
            beginLabel.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
            beginLabel.position = CGPoint(x: frame.midX, y: beginLabelYPos)

            addChild(beginLabel)
        }
       
        // Setup game over card
        self.gameOverCard = SKSpriteNode(texture: textures["game_over"]!)
        if let gameOverCard = self.gameOverCard {
            gameOverCard.setScale(globalScale * 0.17)
            gameOverCard.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
            gameOverCard.position = CGPoint(
                x: view.frame.midX,
                y: view.frame.midY + gameOverCard.frame.height / 2 // Position slightly above the middle
            )
            
            addChild(gameOverCard)
        }
    }
   
    private func configureBackgrounds(using view: SKView){
        // Configure an initial background
        self.backgroundA = SKSpriteNode(texture: textures["background"])
        if let backgroundA = self.backgroundA {
            backgroundA.setScale(globalScale)
            backgroundA.anchorPoint = CGPoint(x: 0.5, y: 0) // Anchor at midbottom
            backgroundA.zPosition = CGFloat(TSGameObjectType.background.rawValue)
            backgroundA.position = CGPoint(
                x: view.frame.midX,
                y: view.frame.minY
            )
           
            addChild(backgroundA)
            
            // Configure rest of backgrounds based off this one
            self.backgroundB = backgroundA.copy() as? SKSpriteNode
            self.backgroundC = backgroundA.copy() as? SKSpriteNode
            self.backgroundD = backgroundA.copy() as? SKSpriteNode

            if let backgroundB = self.backgroundB, let backgroundC = self.backgroundC, let backgroundD = self.backgroundD {
                backgroundB.position = CGPoint(
                    x: view.frame.midX,
                    y: backgroundA.frame.minY - backgroundA.frame.height
                )
               
                addChild(backgroundB)
                
                backgroundC.position = CGPoint(
                    x: view.frame.midX,
                    y: backgroundA.frame.minY + backgroundA.frame.height * 2
                )
               
                addChild(backgroundC)
                
                backgroundD.position = CGPoint(
                    x: view.frame.midX,
                    y: backgroundA.frame.minY + backgroundA.frame.height
                )
                    
                addChild(backgroundD)
            }
        }
    }
   
    private func configurePlayer(using view: SKView){
        // Initialize player
        self.player = TSPlayer(
            scale: globalScale * 0.8,
            texture: textures["player"]!,
            shadow: textures["shadow"]!,
            smokeParticles: SKEmitterNode(fileNamed: "turbo")!,
            target: self,
            startPos: CGPoint(
                x: view.frame.width / 2,
                y: (textures["player"]!.size().height * 0.8 * globalScale / 2) + (30 * globalScale) // Positioning OK, everything's by global scale
            )
        )
        
        if let player = self.player, let backgroundA = self.backgroundA {
            // Assign the player lanes
            player.calculateLanes(
                scale: globalScale,
                offshoot: (backgroundA.frame.width - view.frame.width) * 0.5, // Although this COULD be clearer, everything's relative to a scale so is OK
                pad: 18,
                laneWidth: 22,
                laneCount: 3
            )
        }
    }
    
    private func configureSpider(){
        if let player = self.player {
            // Build array of arrow frames
            let arrowsFrames = [
                textures["arrows_0"]!,
                textures["arrows_1"]!,
                textures["arrows_2"]!,
                textures["arrows_3"]!
            ]
            
            // Need at least 1 attack target; means player lanes must be initialized first!
            if !player.getLanes().isEmpty {
                TSSpider.shared.configure(
                    scale: globalScale,
                    texture: textures["spider"]!,
                    cageTexture: textures["forbidden"]!,
                    arrowsFrames: arrowsFrames,
                    attackTargets: player.getLanes(),
                    targetScene: self
                )
            }
        }
    }
   
    private func configureScoreKeeper(){
        TSScoreKeeper.shared.configureLabel(self)
    }
   
    private func configureSpawner(){
        // Organize powerup and car textures for spawner to draw from
        let powerupTextures: Dictionary<TSGameObjectType, SKTexture> = [
            .freshener : textures["freshener"]!,
            .drink : textures["drink"]!,
            .horn : textures["horn"]!
        ]
      
        let carTextures = [
            textures["car_green"]!,
            textures["car_orange"]!,
            textures["car_red"]!,
            textures["car_yellow"]!,
        ]
        
        // Setup spawner
        if let player = self.player {
            TSSpawnKeeper.shared.configure(
                targetScene: self,
                possibleCars: carTextures,
                possibleLanes: player.getLanes(),
                powerupTextures: powerupTextures,
                carShadow: textures["shadow"]!,
                carScale: globalScale * 0.8
            )
        }
    }
   
    private func configureEffectHandler(using scene: SKScene){
        TSEffectKeeper.shared.configure(
            overlay: textures["blank"]!,
            labelFontName: "FFF Forward",
            targetScene: scene
        )
    }
    
    private func setGameState(to state: TTGameState){
        // Prevent resetting
        if state == gameState {
            return
        }

        self.lastGameState = self.gameState
        self.gameState = state
       
        if let gameOverCard = self.gameOverCard, let titleCard = self.titleCard, let beginLabel = self.beginLabel, let player = self.player {
            switch state {
            case .title:
                gameOverCard.isHidden = true
                titleCard.isHidden = false
                beginLabel.isHidden = false
                
                player.unfreeze()
                player.clearState()
                
                TSSpider.shared.unfreeze()
                TSSpider.shared.clearState()
                
                TSSpawnKeeper.shared.clearState()
                
                TSScoreKeeper.shared.clearState()
                
                TSSpeedKeeper.shared.unfreeze()
                TSSpeedKeeper.shared.clearState()
                
                TSEffectKeeper.shared.clearAll()
            case .inGame:
                gameOverCard.isHidden = true
                titleCard.isHidden = true
                beginLabel.isHidden = true
                
                TSSpider.shared.start()
                
                TSSpawnKeeper.shared.startTimer()
                
                TSScoreKeeper.shared.startTimer()
                TSScoreKeeper.shared.showLabel()
                
                TSEffectKeeper.shared.enableLabel()
            case .gameOver:
                gameOverCard.isHidden = false
                titleCard.isHidden = true
                beginLabel.isHidden = true
                
                player.freeze()
                
                TSSpider.shared.freeze()
                
                TSSpawnKeeper.shared.stopTimer()
               
                TSScoreKeeper.shared.stopTimer()
                TSScoreKeeper.shared.keepScore()
                TSScoreKeeper.shared.hideLabel()
                
                TSSpeedKeeper.shared.freeze()
                
                TSEffectKeeper.shared.pauseAll()
                TSEffectKeeper.shared.disableLabel()
            case .none:
                return
            }
        }
    }

    private func scrollBackground(using view: SKView){
        if let backgroundA = self.backgroundA, let backgroundB = self.backgroundB, let backgroundC = self.backgroundC, let backgroundD = self.backgroundD {
            let tpTop = view.frame.minY + view.frame.height * 2 // Where background will teleport to once offscreen
            let tpBottom = view.frame.minY - view.frame.height // Where background will teleport from once offscreen
            
            let dy = CGFloat(TSSpeedKeeper.shared.getSpeed()) * deltaTime // Velocity increment of background
            
            // Move all towards bottom
            backgroundA.position.y -= dy
            backgroundB.position.y -= dy
            backgroundC.position.y -= dy
            backgroundD.position.y -= dy
          
            // Teleport to top if hit bottom
            if backgroundA.position.y <= tpBottom {
                backgroundA.position.y = tpTop - (tpBottom - backgroundA.position.y)
            }

            if backgroundB.position.y <= tpBottom {
                backgroundB.position.y = tpTop - (tpBottom - backgroundB.position.y)
            }
           
            if backgroundC.position.y <= tpBottom {
                backgroundC.position.y = tpTop - (tpBottom - backgroundC.position.y)
            }
            
            if backgroundD.position.y <= tpBottom {
                backgroundD.position.y = tpTop - (tpBottom - backgroundD.position.y)
            }
        }
    }
   
    private func runGameLogic(using view: SKView){
        scrollBackground(using: view)
         
        if let player = self.player {
            player.update(with: deltaTime)
            TSSpider.shared.update(with: deltaTime)
            TSSpawnKeeper.shared.update()
            TSSpeedKeeper.shared.update()
            TSEffectKeeper.shared.update(with: deltaTime)
        }
    }

    /// Checks if the passed node is that specific body in a collision contact
    func isBody(_ target: SKSpriteNode, which body: SKPhysicsBody) -> Bool {
        if let targetBitMask = target.physicsBody?.categoryBitMask {
            return body.categoryBitMask == targetBitMask
        }
        
        return false
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Check for collisions with the player
        if let player = self.player {
            let bodyA = contact.bodyA
            let bodyB = contact.bodyB
            
            let playerIsBodyA = isBody(player.getNode(), which: bodyA)
            let playerIsBodyB = isBody(player.getNode(), which: bodyB)
            
            // If the contact doesn't contain the player, don't process any collision
            if !playerIsBodyA && !playerIsBodyB {
                return
            }
            
            // Then, determine which of the 2 bodies is the other body
            var otherBody: SKPhysicsBody
            
            if (playerIsBodyA){
                otherBody = bodyB
            } else {
                otherBody = bodyA
            }
            
            // Game loss case
            if otherBody.categoryBitMask == TSEntity.categoryBitmaskOf(.car) || otherBody.categoryBitMask == TSEntity.categoryBitmaskOf(.spider) {
                setGameState(to: .gameOver)
                hapticFeedback.impactOccurred(intensity: 1.0)
                TSAudioKeeper.shared.playSoundAsync("crash", target: self)
            // Powerup collect case
            } else {
                // Run powerup effect
                switch otherBody.categoryBitMask {
                    case TSEntity.categoryBitmaskOf(.freshener):
                    TSEffectKeeper.shared.beginEffect(for: .freshener)
                    case TSEntity.categoryBitmaskOf(.horn):
                    TSEffectKeeper.shared.beginEffect(for: .horn)
                    case TSEntity.categoryBitmaskOf(.drink):
                    TSEffectKeeper.shared.beginEffect(for: .drink)
                    default:
                        break
                }
                    
                // Play collection SFX
                TSAudioKeeper.shared.playSoundAsync("powerup", target: self)
               
                // Play haptic
                hapticFeedback.impactOccurred(intensity: 0.75)
                
                // Remove the powerup
                TSSpawnKeeper.shared.removePowerup(with: otherBody.node as! SKSpriteNode)
            }
        }
    }

    @objc func handleTap(_ tap: UITapGestureRecognizer){
        if gameState == .gameOver {
            setGameState(to: .title)
        }
    }
 
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
        // Play haptic feedback
        hapticFeedback.impactOccurred(intensity: 0.5)

        // Play sound effect
        TSAudioKeeper.shared.playSoundAsync("switch", target: self)
        
        // Cannot swipe in gameover, need to tap
        if gameState == .gameOver {
            return
        }
        
        // If is in title screen, begin game!
        if gameState == .title {
            setGameState(to: .inGame)
        }
       
        // Change player direction
        if let player = self.player {
            player.changeDirection(to: gesture.direction)
        }
    }
   
    override func didMove(to view: SKView) {
        // Prepare game context
        prepareGameContext()
        
        // Configure game components
        setGlobalScale(from: view)
        configurePhysics()
        configureGestureRecognizers(using: view)
        configureTextures()
        configureBackgrounds(using: view)
        configurePlayer(using: view)
        configureSpider()
        configureScoreKeeper()
        configureSpawner()
        configureEffectHandler(using: self)
        configureGUIElements(using: view)

        // Add observers to check if we've left/re-entered the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onReturnFromBackground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // Start at title screen
        setGameState(to: .title)
    }
  
    @objc private func onEnterBackground(){
        // The only situation that's going to cause issues on pause/unpause is when we-re in game
        if self.gameState == .inGame {
            if let player = self.player {
                player.freeze()
            }
            
            TSSpider.shared.freeze()
           
            TSSpawnKeeper.shared.stopTimer()

            TSScoreKeeper.shared.stopTimer()
            
            TSSpeedKeeper.shared.freeze()
            
            TSEffectKeeper.shared.pauseAll()
        }
        
        self.gameIsPaused = true
    }
   
    @objc private func onReturnFromBackground(){
        if self.gameState == .inGame {
            if let player = self.player {
                player.unfreeze()
            }
            
            TSSpider.shared.unfreeze()
           
            TSSpawnKeeper.shared.startTimer()

            TSScoreKeeper.shared.startTimer()
            
            TSSpeedKeeper.shared.unfreeze()
            
            TSEffectKeeper.shared.resumeAll()
        }
        
        self.gameIsPaused = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = self.gameIsPaused ? 0 : currentTime - lastUpdateTime as CGFloat

        if let view = self.view {
            runGameLogic(using: view)
        }
        
        lastUpdateTime = currentTime
    }
}
