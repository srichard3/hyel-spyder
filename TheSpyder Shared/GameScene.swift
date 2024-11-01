import SpriteKit
import GameplayKit
import UIKit

// TODO: Needed fixes
// - [ ] Upon exiting and leaving app, bg. disappears, player goes crazy (very likely related to deltaTime calculation!)
// - [ ] When the game is going really fast, you can see the background briefly change position (add a third background  maybe?)

/// Links a shadow to its caster
class ShadowInfo{
    var shadow: SKSpriteNode!
    var caster: SKSpriteNode!
    
    init(shadow: SKSpriteNode, caster: SKSpriteNode){
        self.shadow = shadow
        self.caster = caster
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameObjectType {
        case entity
        case background
    }

    // MARK: Delta Time
    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0
   
    // MARK: Textures
    let tBackground = SKTexture(imageNamed: "road")
    let tPlayer = SKTexture(imageNamed: "player")
    let tSpider = SKTexture(imageNamed: "spider")
    let tShadow = SKTexture(imageNamed: "shadow")
   
    // MARK: Backgrounds
    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!
  
    // MARK: Scaling
    var globalScale: CGFloat = 1
    var entityScale: CGFloat = 0.8

    // MARK: Player
    var player: SKSpriteNode!
    var playerLanes = Array<CGPoint>()
    var playerLane = 0
    var playerRotation: CGFloat = 0
    let playerCategory: UInt32 = 0x1 << 0
       
    // MARK: Spider
    var spider: SKSpriteNode!
    var spiderPosition: CGPoint!
    var spiderAttackTimer: Timer!
    let spiderAttackInterval: TimeInterval = 5
    let spiderPeekDuration: TimeInterval = 3.0
    let spiderSnatchDuration: TimeInterval = 0.5

    // MARK: Cars
    var carSpawnTimer: Timer!
    var carSpawnInterval: TimeInterval = 0.75
    let carCategory: UInt32 = 0x1 << 1
    var carsInTheScene = Array<SKSpriteNode>()
    var possibleCars: [SKTexture] = [
        SKTexture(imageNamed: "car_g"),
        SKTexture(imageNamed: "car_o"),
        SKTexture(imageNamed: "car_r"),
        SKTexture(imageNamed: "car_y")
    ]

    // MARK: Shadows
    var sceneShadowInfo = Array<ShadowInfo>()
   
    // MARK: Score
    var scoreLabel: SKLabelNode!

    var scoreTimer: Timer!
    var scoreAddInterval: TimeInterval = 1

    var scoreMultiplier: CGFloat = 1.0
    var scoreMultiplierIncrease: CGFloat = 0.25

    var baseScore: Int = 5
    var currentScore: Int = 0

    // MARK: Game Speed
    var gameSpeed: CGFloat = 600
    var speedupAmount: CGFloat = 120
    var scoreUntilSpeedup: Int = 50
    var scoreUntilSpeedupIncrease: Int = 100

    // MARK: Haptic Feedback
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    /// Get the appropriate scale factor relative to the specified object type.
    /// Intended to make scale calculations a bit more readable!
    func scaleFactor(of type: GameObjectType) -> CGFloat {
        switch type {
        case .entity:
            return globalScale * entityScale
        case .background:
            return globalScale
        }
    }
  
    /// Applies scale to given object pertaining to type.
    func applyScale(to object: SKSpriteNode, of type: GameObjectType) {
        switch type {
        case .entity:
            object.setScale(globalScale * entityScale)
        case .background:
            object.setScale(globalScale)
        }
    }

    override func didMove(to view: SKView) {
        // Get scale needed to make background fill screen; resizing will be based off this scale factor
        let xScaleFactor = view.frame.width / tBackground.size().width
        let yScaleFactor = view.frame.height / tBackground.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
        
        // Setup textures
        tBackground.filteringMode = .nearest
        tPlayer.filteringMode = .nearest
        tSpider.filteringMode = .nearest
        tShadow.filteringMode = .nearest
       
        for carTexture in possibleCars {
            carTexture.filteringMode = .nearest
        }
    
        // Setup sprites
        // Layers:
        // -1 -> BG
        //  0 -> Shadows
        //  1 -> Cars
        //  2 -> Player
        //  3 -> GUI
        
        // Setup background A
        backgroundA = SKSpriteNode(texture: tBackground)

        applyScale(to: backgroundA, of: .background)
        backgroundA.zPosition = -1
        backgroundA.position = CGPoint(
            x: view.frame.width / 2,
            y: view.frame.height / 2
        )

        addChild(backgroundA)

        // Setup background B
        backgroundB = backgroundA.copy() as? SKSpriteNode
        backgroundB.position.y = backgroundA.position.y + backgroundA.size.height

        addChild(backgroundB)
       
        // Setup player
        player = SKSpriteNode(texture: tPlayer)

        applyScale(to: player, of: .entity)
        player.zPosition = 2
        player.position = CGPoint(
            x: view.frame.width / 2,
            y: (player.frame.height / 2) + (30 * scaleFactor(of: .entity)) //  Place the player an arbitrary value above the bottom of the screen, multiplied by the global scale
        )
        
        addChild(player)
    
        // Give player a shadow
        let playerShadow = SKSpriteNode(texture: tShadow)
        
        applyScale(to: playerShadow, of: .entity)
        playerShadow.alpha = 0.3
        playerShadow.zPosition = 0

        let playerShadowInfo = ShadowInfo(shadow: playerShadow, caster: player)

        addChild(playerShadow)
        
        sceneShadowInfo.append(playerShadowInfo)

        // Create swipe recognizers for left and right and add them to this scene
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))) // The _: effectively makes it so the recognizer passes itself into HandleSwipe
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        // Calculate player lanes
        let offshoot = (backgroundA.frame.width - view.frame.width) * 0.5   // Amt. of the background image that's outside the view
        let lanePad = 18.0      // Space between start of background image and first lane
        let laneWidth = 22.0    // Width of one lane
        let laneCount = 3       // Amt. of lanes

        for i in stride(from: 0, to: laneCount, by: 1) {
            let t = CGFloat(i)
            playerLanes.append(
                CGPoint(
                    x: (lanePad + (t * laneWidth) + (laneWidth / 2 - t)) * scaleFactor(of: .background) - offshoot,
                    y: player.position.y
                )
            )
            
            // Example lane calculations:
            // lane 0 = 18 + 11
            // lane 1 = 18 + 22 + 10
            // lane 3 = 18 + 22 + 22 + 9
            // ...
        }
        
        // Move player to center lane
        playerLane = Int(playerLanes.count / 2)
        
        // Schedule game timers
        carSpawnTimer = Timer.scheduledTimer(timeInterval: carSpawnInterval, target: self, selector: #selector(spawnCar), userInfo: nil, repeats: true)
        scoreTimer = Timer.scheduledTimer(timeInterval: scoreAddInterval, target: self, selector: #selector(addScore), userInfo: nil, repeats: true)
    
        // Bind the physics world to this scene
        self.physicsWorld.contactDelegate = self
        
        // We will use our own speed calculations so don't use gravity
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
           
        // Setup score label
        scoreLabel = SKLabelNode(text: "\(currentScore)")

        scoreLabel.fontName = "FFF Forward" // Use the name of the font, not the file name
        scoreLabel.fontSize = 32
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY + frame.midY / 2)
        scoreLabel.zPosition = 3

        addChild(scoreLabel)
        
        // Set up spider
        spider = SKSpriteNode(texture: tSpider)

        applyScale(to: spider, of: .entity)
        spider.zPosition = 2
        spider.position = CGPoint(
            x: frame.midX,
            y: -spider.frame.height
        )
      
        spiderPosition = spider.position // This secondary position will be used to lerp

        addChild(spider)
        
        // Its timer too!
        spiderAttackTimer = Timer.scheduledTimer(withTimeInterval: spiderAttackInterval, repeats: false) { timer in
            timer.invalidate()
            self.spiderAttack() // This will re-initialize the attack timer; we need to do this because there are timed events inside this function that would conflict with this timer
        }
    }

    @objc func spiderAttack(){
        // Pick random lane's x value
        let chosenLaneX: CGFloat = playerLanes[Int.random(in: 0..<playerLanes.count)].x
        
        // Move to peek
        let moveToPeek = SKAction.run {
            self.spiderPosition.x = chosenLaneX
            self.spiderPosition.y = 0
        }
        
        // Wait
        let stayPeeked = SKAction.wait(forDuration: spiderPeekDuration)
        
        // Snatch!
        let snatch = SKAction.run {
            self.spiderPosition.x = chosenLaneX
            self.spiderPosition.y = self.player.position.y
        }
        
        // Stay in snatching position for a bit
        let staySnatching = SKAction.wait(forDuration: spiderSnatchDuration)
        
        // Move back down
        let moveBackDown = SKAction.run {
            self.spiderPosition.x = self.frame.midX
            self.spiderPosition.y = -self.spider.frame.height
        }
    
        // Reinitialize timer
        let restartTimer = SKAction.run {
            self.spiderAttackTimer = Timer.scheduledTimer(withTimeInterval: self.spiderAttackInterval, repeats: true) { timer in
                timer.invalidate()
                self.spiderAttack()
            }
        }
        
        // Run sequence
        let sequence = [
            moveToPeek,
            stayPeeked,
            snatch,
            staySnatching,
            moveBackDown,
            restartTimer
        ]
        
        spider.run(SKAction.sequence(sequence))
    }
   
    func moveSpider(){
        let smoothTime = 7.5
        
        spider.position.x = lerp(start: spider.position.x, end: spiderPosition.x, t: smoothTime * deltaTime)
        spider.position.y = lerp(start: spider.position.y, end: spiderPosition.y, t: smoothTime * deltaTime)
    }
    
    func handleGameSpeed(){
        // If we surpass the current speedup threshold, increase game speed, score multiplier, and raise the threshold!
        if currentScore >= scoreUntilSpeedup {
            gameSpeed += speedupAmount
            scoreUntilSpeedup += scoreUntilSpeedupIncrease
            scoreMultiplier += scoreMultiplierIncrease
        }
    }

    @objc func addScore(){
        currentScore += Int(CGFloat(baseScore) * scoreMultiplier)
        scoreLabel.text = "\(currentScore)"
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
        // Play haptic feedback
        hapticFeedback.impactOccurred()

        // Change player direction
        switch (gesture.direction){
        case .left:
            if playerLane - 1 >= 0 {
                playerLane -= 1
            }
        case.right:
            if playerLane + 1 <= playerLanes.count - 1 {
                playerLane += 1
            }
        default:
            break
        }
    }
   
    func scrollBackground(){
        let dy = gameSpeed * deltaTime
                
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
 
    /// Linear interpolation like in Unity.
    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat{
        return (1 - t) * start + t * end
    }
    
    /// Smoothly moves the player between the calculated lanes
    func movePlayer(){
        let smoothTime = 7.5
      
        player.position.x = lerp(start: player.position.x, end: playerLanes[playerLane].x, t: smoothTime * deltaTime)
        
        // Not necessary:
        // player.position.y = lerp(start: player.position.y, end: playerLanes[playerLane].y, t: smoothTime * deltaTime)
      
        // Take a small fraction of the inverted remaining distance to the target lane to rotate the player a bit
        let xTargetLaneDistance = playerLanes[playerLane].x - player.position.x
        player.zRotation = lerp(
            start: player.zRotation,
            end: -xTargetLaneDistance * 0.0125,
            t: smoothTime * deltaTime
        )
    }
  
    @objc func spawnCar(){
        // Pick a random lane and car
        let chosenLane: CGPoint = playerLanes[Int.random(in: 0..<playerLanes.count)]
        let chosenCar: SKSpriteNode = SKSpriteNode(texture: possibleCars[Int.random(in: 0..<possibleCars.count)])

        // Set up the car
        applyScale(to: chosenCar, of: .entity)
        chosenCar.zPosition = 1
        chosenCar.position = CGPoint(
            x: chosenLane.x,
            y: self.frame.height + chosenCar.frame.height + (10 * scaleFactor(of: .background))
        )
        chosenCar.physicsBody = SKPhysicsBody(rectangleOf: chosenCar.size)
        chosenCar.physicsBody?.isDynamic = true
        chosenCar.physicsBody?.categoryBitMask = carCategory // Is a car
        chosenCar.physicsBody?.contactTestBitMask = playerCategory // That checks for contact with player
        chosenCar.physicsBody?.collisionBitMask = 0 // But doesn't physically respond to that collision
        
        self.addChild(chosenCar)

        carsInTheScene.append(chosenCar)
        
        // Give it a shadow
        let chosenCarShadow = SKSpriteNode(texture: tShadow)
        
        applyScale(to: chosenCarShadow, of: .entity)
        chosenCarShadow.alpha = 0.3
        chosenCarShadow.zPosition = 0
        
        let shadowInfo = ShadowInfo(shadow: chosenCarShadow, caster: chosenCar)
       
        self.addChild(chosenCarShadow)
        
        sceneShadowInfo.append(shadowInfo)
    }

    func updateCars(){
        var i = 0
      
        while i < carsInTheScene.count {
            let car = carsInTheScene[i]
           
            // Remove any offscreen cars; this will trigger their shadow's removal as well
            if car.position.y <= -car.frame.height / 2 {
                car.removeFromParent()
                carsInTheScene.remove(at: i)
            }
           
            else {
                // Any cars on screen should instantly respond to game speed changes, not just newly spawned ones
                let dy: CGFloat = (gameSpeed - 25 * scaleFactor(of: .background)) * deltaTime
                car.position.y -= dy
               
                // Move up!
                i = i + 1
            }
        }
    }
   
    func updateShadows() {
        var i = 0
        while i < sceneShadowInfo.count {
            let info = sceneShadowInfo[i]

            // If the caster has been removed from the scene, remove this shadow and this info entry
            if info.caster.scene == nil {
                info.shadow.removeFromParent()
                sceneShadowInfo.remove(at: i)
            }
            
            else {
                // Keep shadows on top of their casters
                info.shadow.position = info.caster.position
                info.shadow.zRotation = info.caster.zRotation
               
                // Go up!
                i = i + 1
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = currentTime - lastUpdateTime as CGFloat
        
        scrollBackground()
        movePlayer()
        moveSpider()
        updateCars()
        updateShadows()
        handleGameSpeed()

        lastUpdateTime = currentTime
    }
}
