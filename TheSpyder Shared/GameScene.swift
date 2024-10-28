import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0
    
    let tBackground = SKTexture(imageNamed: "road")
    let tPlayer = SKTexture(imageNamed: "player")
    
    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!
    var player: SKSpriteNode!
   
    var globalScale: CGFloat = 1
    var entityScale: CGFloat = 0.8
    var scrollingSpeed: CGFloat = 500
    
    var playerLanes = Array<CGPoint>()
    var playerLane = 0
    var playerRotation: CGFloat = 0

    var possibleCars: [SKTexture] = [
        SKTexture(imageNamed: "car_g"),
        SKTexture(imageNamed: "car_o"),
        SKTexture(imageNamed: "car_r"),
        SKTexture(imageNamed: "car_y")
    ]
   
    var gameTimer: Timer!
    
    let playerCategory: UInt32 = 0x1 << 0
    let carCategory: UInt32 = 0x1 << 1
    var carsInTheScene = Array<SKSpriteNode>()
    var carSpawnInterval: TimeInterval = 0.75
    
    enum GameObjectType {
        case entity
        case background
    }
  
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
        // Get scale needed to make background fill screen; we will scale everything by this
        // TODO: Edit asset so that backgrounds + entities have same PPI
        
        let xScaleFactor = view.frame.width / tBackground.size().width
        let yScaleFactor = view.frame.height / tBackground.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
        
        // Setup textures
        
        tBackground.filteringMode = .nearest
        tPlayer.filteringMode = .nearest
       
        for carTexture in possibleCars {
            carTexture.filteringMode = .nearest
        }
        
        // Setup sprites
        
        backgroundA = SKSpriteNode(texture: tBackground)
        applyScale(to: backgroundA, of: .background)
        backgroundA.position = CGPoint(
            x: view.frame.width / 2,
            y: view.frame.height / 2
        )
        addChild(backgroundA)
        
        backgroundB = backgroundA.copy() as? SKSpriteNode
        backgroundB.position.y = backgroundA.position.y + backgroundA.size.height
        addChild(backgroundB)
        
        player = SKSpriteNode(texture: tPlayer)
        applyScale(to: player, of: .entity)
        player.position = CGPoint(
            x: view.frame.width / 2,
            y: (player.frame.height / 2) + (30 * scaleFactor(of: .entity)) //  Place the player an arbitrary value above the bottom of the screen, multiplied by the global scale
        )
        
        addChild(player)
        
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
        
        // Schedule the game timer to spawn new cars at the set interval
        gameTimer = Timer.scheduledTimer(timeInterval: carSpawnInterval, target: self, selector: #selector(spawnCar), userInfo: nil, repeats: true)
    
        // Bind the physics world to this scene
        self.physicsWorld.contactDelegate = self
        
        // We will use our own speed calculations so don't use gravity
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }
   
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
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
        let dy = CGFloat(scrollingSpeed) * deltaTime
                
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
        chosenCar.position.x = chosenLane.x
        chosenCar.position.y = self.frame.height + chosenCar.frame.height + (10 * scaleFactor(of: .background))
        chosenCar.physicsBody = SKPhysicsBody(rectangleOf: chosenCar.size)
        chosenCar.physicsBody?.isDynamic = true
        chosenCar.physicsBody?.categoryBitMask = carCategory // Is a car
        chosenCar.physicsBody?.contactTestBitMask = playerCategory // That checks for contact with player
        chosenCar.physicsBody?.collisionBitMask = 0 // But doesn't physically respond to that collision
       
        // Add it to both the scene and our tracker array
        self.addChild(chosenCar)
        carsInTheScene.append(chosenCar)
    }

    func updateCars(){
        for car in carsInTheScene {
            // Remove offscreen cars from the scene
            if car.position.y <= -car.frame.height / 2 {
                car.removeFromParent()
                continue
            }
            
            // Any cars on screen should instantly respond to game speed changes, not just newly spawned ones
            let dy: CGFloat = (scrollingSpeed - 25 * scaleFactor(of: .background)) * deltaTime
            car.position.y -= dy
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
        updateCars()
        
        lastUpdateTime = currentTime
    }
}
