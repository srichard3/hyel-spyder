import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case title
        case inGame
        case gameOver
    }

    var gameState: GameState!
    
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
  
    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!

    var titleCard: SKSpriteNode!
    var gameOverCard: SKSpriteNode!
    var beginLabel: SKLabelNode!
    
    var player: Player!
   
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeRight: UISwipeGestureRecognizer!
    var tap: UITapGestureRecognizer!
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    // Might want to move this to a dedicated controller...
    /// Play tremolo/earthquake haptic
    func playTremblingHaptic(){
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
    }

    func setGlobalScale(from view: SKView){
        // The global scale is based on how much we need to scale the background by to cover the whole scene's frame
        let xScaleFactor = view.frame.width / textures["background"]!.size().width
        let yScaleFactor = view.frame.height / textures["background"]!.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
    }
   
    func configurePhysics(){
        self.physicsWorld.contactDelegate = self // Make contact tests take place in this scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Remove gravity
    }
    
    func configureGestureRecognizers(using view: SKView){
        // Set up swipe and tap recognizers and add them to the scene
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))) // The _: effectively makes it so the recognizer passes itself into HandleSwipe
        swipeLeft.direction = .left
       
        view.addGestureRecognizer(swipeLeft)

        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
       
        view.addGestureRecognizer(swipeRight)

        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

        view.addGestureRecognizer(tap)
    }
   
    func configureTextures(){
        // Make all textures resize as nearest neighbor
        for texture in textures.values {
            texture.filteringMode = .nearest
        }
    }
   
    func configureGUIElements(using view: SKView){
        // Setup title card
        titleCard = SKSpriteNode(texture: textures["title"]!)
        
        titleCard.setScale(globalScale * 0.20)
        titleCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
        titleCard.position = CGPoint(
            x: view.frame.midX,
            y: view.frame.midY + titleCard.frame.height / 2
        )
        
        addChild(titleCard)
      
        // Set up begin label
        beginLabel = SKLabelNode(text: "Swipe to Begin!")
     
        beginLabel.fontName = "FFF Forward" 
        beginLabel.fontSize = 16
        beginLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.8, alpha: 1))
        beginLabel.zPosition = CGFloat(GameObjectType.gui.rawValue)
        beginLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50) // 50 was eyeballed

        addChild(beginLabel)
        
        // Setup game over card
        gameOverCard = SKSpriteNode(texture: textures["game_over"]!)
        
        gameOverCard.setScale(globalScale * 0.2)
        gameOverCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
        gameOverCard.position = CGPoint(
            x: view.frame.midX,
            y: view.frame.midY + gameOverCard.frame.height / 2
        )
        
        addChild(gameOverCard)
    }
   
    func configureBackgrounds(using view: SKView){
        // Setup background A
        backgroundA = SKSpriteNode(texture: textures["background"])

        backgroundA.setScale(globalScale)
        backgroundA.zPosition = CGFloat(GameObjectType.background.rawValue)
        backgroundA.position = CGPoint(
            x: view.frame.width / 2,
            y: view.frame.height / 2
        )
       
        addChild(backgroundA)

        // Setup background B
        backgroundB = backgroundA.copy() as? SKSpriteNode
       
        backgroundB.position.y = backgroundA.position.y + backgroundA.size.height
       
        addChild(backgroundB)
    }
   
    func configurePlayer(using view: SKView){
        player = Player(
            scale: globalScale * 0.8,
            texture: textures["player"]!,
            shadow: textures["shadow"]!,
            smokeParticles: SKEmitterNode(fileNamed: "smoke")!,
            target: self,
            startPos: CGPoint(
                x: view.frame.width / 2,
                y: (textures["player"]!.size().height * 0.8 * globalScale / 2) + (30 * globalScale) // MARK: This calculation is being done by hand, using magic numbers that pertain to things that should be variables...
            )
        )
       
        // Assign the player lanes
        player.calculateLanes(
            scale: globalScale,
            offshoot: (backgroundA.frame.width - view.frame.width) * 0.5, // MARK: Everything should be in unscaled pixel coordinates; is this?
            pad: 18,
            laneWidth: 22,
            laneCount: 3
        )
    }
    
    func configureSpider(){
        // Need at least 1 attack target; means player must be initialized first!
        if !player.lanes.isEmpty{
            Spider.shared.configure(
                scale: globalScale,
                texture: textures["spider"]!,
                cageTexture: textures["forbidden"]!,
                attackTargets: player.lanes,
                targetScene: self
            )
        }
    }
   
    func configureScoreKeeper(){
        // Add label to scene
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
        Spawner.shared.configure(
            targetScene: self,
            possibleCars: carTextures,
            possibleLanes: player.lanes,
            powerupTextures: powerupTextures,
            carShadow: textures["shadow"]!,
            carScale: globalScale * 0.8
        )
    }
   
    func configureEffectHandler(using scene: SKScene){
        // Configure the screen overlay
        EffectHandler.shared.configure(
            overlay: textures["blank"]!,
            labelFontName: "FFF Forward",
            targetScene: scene
        )
    }
    
    func setGameState(to state: GameState){
        // Prevent looping transitions
        if state == gameState {
            return
        }

        gameState = state
    
        // MARK: The actions taken in each case have been shoddily put there after testing and seeing what fails, and assuming the only flow is title -> inGame -> gameOver -> title -> ...
        // TODO: Ensure transition actions are robust!
        
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
        case.gameOver:
            gameOverCard.isHidden = false
            titleCard.isHidden = true
            beginLabel.isHidden = true

            player.isFrozen = true
            Spider.shared.freeze()
            
            SpeedKeeper.shared.freeze()

            ScoreKeeper.shared.hideLabel()
            
            Spawner.shared.stop()
            
            EffectHandler.shared.pauseAll()
            EffectHandler.shared.cleanup()
        }
    }

    func scrollBackground(){
        let dy = CGFloat(SpeedKeeper.shared.getSpeed()) * deltaTime
                
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
    
    func runGameLogic(){
        scrollBackground()

        player.update(with: deltaTime)
        Spider.shared.update(with: deltaTime)

        Spawner.shared.update()
        SpeedKeeper.shared.update()
    }

    /// Checks if the passed node is that specific body in a collision contact
    func isBody(_ target: SKSpriteNode, which body: SKPhysicsBody) -> Bool {
        if let targetBitMask = target.physicsBody?.categoryBitMask {
            return body.categoryBitMask == targetBitMask
        }
        
        return false
    }

    func didBegin(_ contact: SKPhysicsContact) {
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
        
        
        // No actions save for a tap to reset should be taken in game over
        if gameState == .gameOver {
            return
        }
        
        // If is in title screen, begin game!
        if gameState == .title {
            setGameState(to: .inGame)
        }
       
        // Change player direction
        player.changeDirection(to: gesture.direction)
    }
   
    override func didMove(to view: SKView) {
        // Configure everything
        setGlobalScale(from: view)
        configurePhysics()
        configureGestureRecognizers(using: view)
        configureTextures()
        configureGUIElements(using: view)
        configureBackgrounds(using: view)
        configurePlayer(using: view)
        configureSpider()
        configureScoreKeeper()
        configureSpawner()
        configureEffectHandler(using: self)
        
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
