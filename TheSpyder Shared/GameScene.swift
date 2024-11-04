import SpriteKit
import GameplayKit
import UIKit

enum GameObjectType: UInt32 {
    case background = 0
    case shadow = 1
    case car = 2
    case player = 3
    case spider = 4
    case gui = 5
}

class Entity{
    public let type: GameObjectType
    public let node: SKSpriteNode
   
    public var position: CGPoint
    public var rotation: CGFloat
    public var smoothTime: CGFloat = 7.5

    private let shadowNode: SKSpriteNode
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startRotation: CGFloat = 0){
        self.type = type
       
        // Setup body node
        node = SKSpriteNode(texture: texture)
     
        // Set its scale
        switch type {
        default:
            node.setScale(scale * 0.8)
        }
        
        // Layers:
        // -1 -> BG
        //  0 -> Shadows
        //  1 -> Cars
        //  2 -> Player
        //  3 -> GUI
        node.zPosition = CGFloat(type.rawValue)
        
        // Position & rotate
        self.position = startPos
        self.rotation = startRotation
        
        // Setup its physics body
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.categoryBitMask = type.rawValue
    
        switch type {
        case .car:
            node.physicsBody?.contactTestBitMask = 0x1 << 0
        case .player:
            node.physicsBody?.contactTestBitMask = 0x1 << 1
        case .spider:
            node.physicsBody?.contactTestBitMask = 0x1 << 2
        default:
            node.physicsBody?.contactTestBitMask = 0
        }
       
        // Add to scene
        target.addChild(node)

        // Setup shadow node
        shadowNode = SKSpriteNode(texture: shadow)

        shadowNode.zPosition = CGFloat(GameObjectType.shadow.rawValue)
        shadowNode.alpha = 0.2

        target.addChild(shadowNode)
    }
 
    // MARK: Not exactly related to entities (but used by them), might wanna move somewhere else?
    public static func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat{
        return (1 - t) * start + t * end
    }

    /// Smoothly move the entity using linear interpolation.
    public func lerpMove(smoothTime: CGFloat, deltaTime: CGFloat = 1){
        node.position.x = Entity.lerp(start: node.position.x, end: position.x, t: smoothTime * deltaTime)
        node.position.y = Entity.lerp(start: node.position.y, end: position.y, t: smoothTime * deltaTime)
        node.zRotation = Entity.lerp(start: node.zRotation, end: rotation, t: smoothTime * deltaTime)
    }

    /// Keep shadow on the caster
    public func update(){
        shadowNode.position = node.position
        shadowNode.zRotation = node.zRotation
    }
}

class Player{
    var entity: Entity
    var lanes = Array<CGPoint>()
    var lane: Int = 0

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.player, startPos: startPos)
    }
   
    /// Calculate position points the player can switch to
    public func calculateLanes(scale: CGFloat, offshoot: CGFloat, pad: CGFloat, laneWidth: CGFloat, laneCount: Int){
        // Clear any previous lane info
        lanes.removeAll();
       
        // Compute new lanes
        // Example lane calculations:
        // lane 0 = 18 + 11
        // lane 1 = 18 + 22 + 10
        // lane 3 = 18 + 22 + 22 + 9
        // ...
        for i in stride(from: 0, to: laneCount, by: 1) {
            let t = CGFloat(i)
            lanes.append(
                CGPoint(
                    x: (pad + (t * laneWidth) + (laneWidth / 2 - t)) * scale - offshoot,
                    y: self.entity.position.y // The desired y-position must be set before calling this!
                )
            )
        }
    }

    /// Try to move to the lane in the given direction
    public func move(towards dir: UISwipeGestureRecognizer.Direction){
        switch dir {
        case .left:
            if lane - 1 >= 0 {
                lane -= 1
            }
        case.right:
            if lane + 1 <= lanes.count - 1 {
                lane += 1
            }
        default:
            return
        }
    }
    
    public func update(){
        // Take a small fraction of the inverted remaining distance to the target lane to rotate the player node a bit when moving it
        let xTargetLaneDistance = lanes[lane].x - entity.node.position.x
        entity.rotation = -xTargetLaneDistance * 0.0125
    }
}

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
            self.entity.position.x = target.x
            self.entity.position.y = 0
        }
        
        // Stay peeked for a bit
        let stayPeeked = SKAction.wait(forDuration: peekDuration)
        
        // Then snatch!
        let snatch = SKAction.run {
            self.entity.position.x = target.x
            self.entity.position.y = target.y
        }
        
        // Stay in snatching position for a bit
        let staySnatched = SKAction.wait(forDuration: snatchDuration)
        
        // Move back down
        let moveBackDown = SKAction.run {
            self.entity.position.x = self.entity.node.parent == nil ? 0 : self.entity.node.parent!.frame.midX
            self.entity.position.y = -self.entity.node.frame.height
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

class Car{
    var entity: Entity
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.car, startPos: startPos)
        
        // Give start vel
        self.entity.node.physicsBody?.velocity = startVel
    }
    
    public func killIfOffFrame(frame: CGRect){
        // MARK: Before re-adding this, remove Entity first
        /*
        if entity.position.y <= -entity.node.frame.height / 2 {
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
        */
    }
}

/// Singleton; keeps track of the player's score
class ScoreKeeper{
    static let shared = ScoreKeeper()
    
    var score: Int = 0

    var baseAward: Int = 5
    var awardTimer: Timer!
    var awardInterval: TimeInterval = 1

    var multiplier: CGFloat = 1.0
    var multiplierIncrement: CGFloat = 0.25
    
    var label: SKLabelNode
 
    // Private initializers prevent external instantiation! Useful for singletons
    private init(){
        // Setup score label
        self.label = SKLabelNode(text: "\(self.score)")

        self.label.fontName = "FFF Forward" // Use the name of the font, not the file name
        self.label.fontSize = 32
        self.label.zPosition = CGFloat(GameObjectType.gui.rawValue)
    }
    
    public func addLabelToScene(_ target: SKScene){
        // Add to target scene
        target.addChild(label)
      
        // Position label using scene dimensions
        self.label.position = CGPoint(x: target.frame.midX, y: target.frame.midY + target.frame.midY / 2)
    }
   
    @objc func addScore(){
        score += Int(CGFloat(baseAward) * multiplier)
        label.text = "\(score)"
    }

    /// Start keeping score
    public func start(){
       
    }
  
    /// Stop keeping score
    public func stop(){
        
    }
}

/// Keeps track of the game speed
class SpeedKeeper{
    static let shared = SpeedKeeper()

    var speed: CGFloat = 600
    var speedupAmount: CGFloat = 120
    var scoreUntilSpeedup: Int = 50
    var scoreUntilSpeedupIncrement: Int = 100
    
    /// Update the speed based on given score
    public func update(){
        // If current score exceeds speedup threshold, increase game speed and score multiplier
        if ScoreKeeper.shared.score >= scoreUntilSpeedup {
            speed += speedupAmount
            scoreUntilSpeedup += scoreUntilSpeedupIncrement
            ScoreKeeper.shared.multiplier += ScoreKeeper.shared.multiplierIncrement
        }
    }
}

/// Handle car spawning
class CarSpawner{
    static let shared = CarSpawner()

    var cars = Array<Car>()
    
    var spawnTimer: Timer?
    var spawnInterval: TimeInterval = 0.75
    
    var possibleCars: [SKTexture]?
    var possibleLanes: [CGPoint]?
    
    public func setPossibleCars(to cars: [SKTexture]){
        // Get possible car spawns as a list of loaded textures
        // We want all texture loading to happen in one place!
        self.possibleCars = cars
    }
   
    public func setPossibleLanes(to lanes: [CGPoint]){
        self.possibleLanes = lanes
    }
    
    @objc func spawnCar(){
        if self.possibleCars == nil || self.possibleLanes == nil {
            return
        }

        // Pick a random lane and car
        let chosenLane: CGPoint = self.possibleLanes![Int.random(in: 0..<self.possibleLanes!.count)]
        let chosenCarTexture: SKTexture = possibleCars![Int.random(in: 0..<possibleCars!.count)]
        
        // TODO: Set up the car using new class structure, the below is the old one
        /*
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
        */
    }
   
    /// Begin spawning cars, giving it a set of possible lanes to pick from
    func start(){
        
    }
   
    /// Stop spawning cars
    func stop(){
        
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case title
        case inGame
        case gameOver
    }

    var globalScale: CGFloat = 1

    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0
    
    let tBackground = SKTexture(imageNamed: "road")
    let tPlayer = SKTexture(imageNamed: "player")
    let tSpider = SKTexture(imageNamed: "spider")
    let tShadow = SKTexture(imageNamed: "shadow")
    let tCars = [
        SKTexture(imageNamed: "car_g"),
        SKTexture(imageNamed: "car_o"),
        SKTexture(imageNamed: "car_r"),
        SKTexture(imageNamed: "car_y")
    ]

    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!
   
    var player: Player!
    var spider: Spider!
    var carSpawner: CarSpawner!
    var scoreKeeper: ScoreKeeper!
    var speedKeeper: SpeedKeeper!
   
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeRight: UISwipeGestureRecognizer!
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    override func didMove(to view: SKView) {
        // The global scale is based on how much we need to scale the background by to cover the whole scene's frame
        let xScaleFactor = view.frame.width / tBackground.size().width
        let yScaleFactor = view.frame.height / tBackground.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
   
        // Set up the scene and its components
        self.physicsWorld.contactDelegate = self                // Make contact tests take place in this scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)      // Remove gravity
           
        // Set up swipe recognizers and add them to the scene
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))) // The _: effectively makes it so the recognizer passes itself into HandleSwipe
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        // Make all textures resize as nearest neighbor
        // MARK: Move to hashmap?
        tBackground.filteringMode = .nearest
        tPlayer.filteringMode = .nearest
        tSpider.filteringMode = .nearest
        tShadow.filteringMode = .nearest
        for texture in tCars {
            texture.filteringMode = .nearest
        }
        
        // Setup background A
        backgroundA = SKSpriteNode(texture: tBackground)

        backgroundA.setScale(globalScale)
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
        player = Player(
            scale: globalScale,
            texture: tPlayer,
            shadow: tShadow,
            target: self
        )
        
        player.entity.position = CGPoint(
            x: view.frame.width / 2,
            y: (player.entity.node.frame.height / 2) + (30 * player.entity.node.yScale) //  Place the player an arbitrary value above the bottom of the screen, multiplied by the global scale
        )

        // Setup spider
        spider = Spider(
            scale: globalScale,
            texture: tSpider,
            shadow: tShadow,
            target: self
        )
        
        spider.entity.position = CGPoint(
            x: frame.midX,
            y: -spider.entity.node.frame.height
        )
       
        // Setup score keeper
        ScoreKeeper.shared.addLabelToScene(self)
        
        // Setup car spawner
        CarSpawner.shared.setPossibleCars(to: tCars)
    }

    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
        // Play haptic feedback
        hapticFeedback.impactOccurred()

        // Change player direction
        player.move(towards: gesture.direction)
    }
   
    func scrollBackground(){
        let dy = SpeedKeeper.shared.speed * deltaTime
                
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
    
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = currentTime - lastUpdateTime as CGFloat

        // Run game functionality here
        
        lastUpdateTime = currentTime
    }
}
