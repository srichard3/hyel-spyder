import SpriteKit

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
        
        player.entity.node.position = CGPoint(
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
        
        spider.entity.node.position = CGPoint(
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
