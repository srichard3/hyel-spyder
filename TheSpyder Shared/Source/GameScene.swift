import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case title
        case inGame
        case gameOver
    }

    var gameState: GameState?
    
    var globalScale: CGFloat = 1

    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0

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
        "car_yellow" : SKTexture(imageNamed: "car_y")
    ]
  
    var backgroundA: SKSpriteNode?
    var backgroundB: SKSpriteNode?

    var titleCard: SKSpriteNode?
    var gameOverCard: SKSpriteNode?
    var beginLabel: SKLabelNode?
    
    var player: Player?
   
    var swipeLeft: UISwipeGestureRecognizer?
    var swipeRight: UISwipeGestureRecognizer?
    var tap: UITapGestureRecognizer?
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    // Might want to move this to a dedicated controller...
    /// Play tremolo/earthquake haptic
    func playTremblingHaptic(){
        /*
        return
        
        hapticFeedback.prepare()
        
        let pulses = 4 // Play this amount of pulses
        let pulseDelay = 0.1 // Separated by this amount of time
       
        // Schedule all pulses to run at (current time) + (pulseDelay * i) on a background thread
        for i in 0..<pulses {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + (pulseDelay * TimeInterval(i))) {
                // Also make the intensity go down for every pulse
                self.hapticFeedback.impactOccurred(intensity: 1.0 - (1.0 / CGFloat(pulses)) * CGFloat(i))
            }
        }
        */
    }

    func setGlobalScale(from view: SKView){
        // Fill the screen regardless of anything
        self.scaleMode = .aspectFill
        
        // The global scale is based on how much we need to scale the background by to cover the whole scene's frame
        let xScaleFactor = view.frame.width / textures["background"]!.size().width
        let yScaleFactor = view.frame.height / textures["background"]!.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
    }
   
    func configurePhysics(){
        self.physicsWorld.contactDelegate = self // Make contact tests take place in this scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Remove gravity
    }
   
    /// Sets up left, right, and tap gesture recognizers
    func configureGestureRecognizers(using view: SKView){
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
    func configureTextures(){
        for texture in textures.values {
            texture.filteringMode = .nearest
        }
    }
   
    func configureGUIElements(using view: SKView){
        // Setup title card
        let titleCardScale = 0.2
        
        self.titleCard = SKSpriteNode(texture: textures["title"]!)
        if let titleCard = self.titleCard {
            titleCard.setScale(globalScale * titleCardScale)
            titleCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
            titleCard.position = CGPoint(
                x: view.frame.midX,
                y: view.frame.midY + titleCard.frame.height / 2
            )
            
            addChild(titleCard)
        }
        
        // Set up begin label
        var beginLabelYPos: CGFloat
      
        // Begin label offset is midpoint between player frame top and title card bottom
        if let playerFrame = self.player?.entity.node.frame, let titleCardFrame = self.titleCard?.frame {
            beginLabelYPos = playerFrame.maxY + (titleCardFrame.minY - playerFrame.maxY) / 2.0
        } else {
            beginLabelYPos = frame.midY // Fall back to screen center
        }
        
        self.beginLabel = SKLabelNode(text: "Swipe to Begin!")
        if let beginLabel = self.beginLabel {
            beginLabel.fontName = "FFF Forward"
            beginLabel.fontSize = 16
            beginLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.8, alpha: 1))
            beginLabel.zPosition = CGFloat(GameObjectType.gui.rawValue)
            beginLabel.position = CGPoint(x: frame.midX, y: beginLabelYPos)

            addChild(beginLabel)
        }
       
        // Setup game over card
        self.gameOverCard = SKSpriteNode(texture: textures["game_over"]!)
        if let gameOverCard = self.gameOverCard {
            gameOverCard.setScale(globalScale * 0.2)
            gameOverCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
            gameOverCard.position = CGPoint(
                x: view.frame.midX,
                y: view.frame.midY + gameOverCard.frame.height / 2 // Position slightly above the middle
            )
            
            addChild(gameOverCard)
        }
    }
   
    func configureBackgrounds(using view: SKView){
        // Setup background A
        self.backgroundA = SKSpriteNode(texture: textures["background"])
        if let backgroundA = self.backgroundA  {
            backgroundA.setScale(globalScale)
            backgroundA.zPosition = CGFloat(GameObjectType.background.rawValue)
            backgroundA.position = CGPoint(
                x: view.frame.width / 2,
                y: view.frame.height / 2
            )
           
            addChild(backgroundA)
           
            // From background A, set up background B
            self.backgroundB = backgroundA.copy() as? SKSpriteNode
            if let backgroundB = self.backgroundB {
                backgroundB.position.y = backgroundA.position.y + backgroundA.size.height
               
                addChild(backgroundB)
            }
        }
    }
   
    func configurePlayer(using view: SKView){
        // Initialize player
        self.player = Player(
            scale: globalScale * 0.8,
            texture: textures["player"]!,
            shadow: textures["shadow"]!,
            smokeParticles: SKEmitterNode(fileNamed: "smoke")!,
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
    
    func configureSpider(){
        if let player = self.player {
            // Need at least 1 attack target; means player lanes must be initialized first!
            if !player.lanes.isEmpty {
                Spider.shared.configure(
                    scale: globalScale,
                    texture: textures["spider"]!,
                    cageTexture: textures["forbidden"]!,
                    attackTargets: player.lanes,
                    targetScene: self
                )
            }
        }
    }
   
    func configureScoreKeeper(){
        ScoreKeeper.shared.configureLabel(self)
    }
   
    func configureSpawner(){
        // Organize powerup and car textures for spawner to draw from
        let powerupTextures: Dictionary<GameObjectType, SKTexture> = [
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
            Spawner.shared.configure(
                targetScene: self,
                possibleCars: carTextures,
                possibleLanes: player.lanes,
                powerupTextures: powerupTextures,
                carShadow: textures["shadow"]!,
                carScale: globalScale * 0.8
            )
        }
    }
   
    func configureEffectHandler(using scene: SKScene){
        EffectHandler.shared.configure(
            overlay: textures["blank"]!,
            labelFontName: "FFF Forward",
            targetScene: scene
        )
    }
    
    func setGameState(to state: GameState){
        // Prevent resetting
        if state == gameState {
            return
        }

        gameState = state
       
        if let gameOverCard = self.gameOverCard, let titleCard = self.titleCard, let beginLabel = self.beginLabel, let player = self.player {
            switch state {
            case .title:
                gameOverCard.isHidden = true
                titleCard.isHidden = false
                beginLabel.isHidden = false
                
                player.recenter()
                player.isFrozen = false // TODO: Make player use similar freezing protocol to spider

                Spider.shared.stop()
                Spider.shared.moveOffscreen(shouldDoInstantly: true)
                Spider.shared.unfreeze()

                Spawner.shared.stop()
                Spawner.shared.clear()

                ScoreKeeper.shared.reset()
                ScoreKeeper.shared.hideLabel()

                SpeedKeeper.shared.reset()
                SpeedKeeper.shared.unfreeze()
            case .inGame:
                gameOverCard.isHidden = true
                titleCard.isHidden = true
                beginLabel.isHidden = true
                
                Spider.shared.start()
                
                Spawner.shared.start()
                
                ScoreKeeper.shared.start()
                ScoreKeeper.shared.unhideLabel()
                EffectHandler.shared.enableLabel()
            case.gameOver:
                gameOverCard.isHidden = false
                titleCard.isHidden = true
                beginLabel.isHidden = true

                player.isFrozen = true
                Spider.shared.freeze()
                
                SpeedKeeper.shared.freeze()

                ScoreKeeper.shared.hideLabel()
                
                Spawner.shared.stop()
                
                EffectHandler.shared.cleanup()
                EffectHandler.shared.disableLabel()
            }
        }
    }

    func scrollBackground(){
        if let backgroundA = self.backgroundA, let backgroundB = self.backgroundB {
            let dy = CGFloat(SpeedKeeper.shared.getSpeed()) * deltaTime // Velocity increment of background
            
            // Move to bottom until off-screen, move to top and restart
            backgroundA.position.y -= dy
            backgroundB.position.y -= dy
           
            if backgroundA.position.y <= -backgroundA.size.height / 2 {
                backgroundA.position.y = backgroundB.position.y + backgroundB.size.height - dy
            }

            if backgroundB.position.y <= -backgroundB.size.height / 2 {
                backgroundB.position.y = backgroundA.position.y + backgroundA.size.height - dy
            }
        }
    }
   
    func runGameLogic(){
        scrollBackground()
         
        if let player = self.player {
            player.update(with: deltaTime)
            Spider.shared.update(with: deltaTime)
            Spawner.shared.update()
            SpeedKeeper.shared.update()
            EffectHandler.shared.update(with: deltaTime)
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
            
            let playerIsBodyA = isBody(player.entity.node, which: bodyA)
            let playerIsBodyB = isBody(player.entity.node, which: bodyB)
            
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
            if otherBody.categoryBitMask == Entity.categoryBitmaskOf(.car) || otherBody.categoryBitMask == Entity.categoryBitmaskOf(.spider) {
                setGameState(to: .gameOver)
                playTremblingHaptic()
                AudioHandler.shared.playSoundAsync("crash", target: self)
            // Powerup collect case
            } else {
                // Run powerup effect
                switch otherBody.categoryBitMask {
                    case Entity.categoryBitmaskOf(.freshener):
                        EffectHandler.shared.runEffect(for: .freshener)
                    case Entity.categoryBitmaskOf(.horn):
                        EffectHandler.shared.runEffect(for: .horn)
                    case Entity.categoryBitmaskOf(.drink):
                        EffectHandler.shared.runEffect(for: .drink)
                    default:
                        break
                }
                    
                // Play collection SFX
                AudioHandler.shared.playSoundAsync("powerup", target: self)
                
                // Remove the powerup
                Spawner.shared.removePowerup(with: otherBody.node as! SKSpriteNode)
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
        hapticFeedback.impactOccurred()

        // Play sound effect
        AudioHandler.shared.playSoundAsync("switch", target: self)
        
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
        // Configure everything
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

        // Start at title screen
        setGameState(to: .title)
    }
   
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = currentTime - lastUpdateTime as CGFloat // MARK: This starts tweaking when we've left the app for a long time; set it correctly in some sort of callback?

        runGameLogic()
        
        lastUpdateTime = currentTime
    }
}
