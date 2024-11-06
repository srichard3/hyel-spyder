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
       
        // Setup player
        player = Player(
            scale: globalScale * 0.8,
            texture: tPlayer,
            shadow: tShadow,
            target: self,
            startPos: CGPoint(
                x: view.frame.width / 2,
                y: (tPlayer.size().height * 0.8 * globalScale / 2) + (30 * globalScale) // MARK: This calculation is being done by hand, using magic numbers that pertain to things that should be variables...
            )
        )
        
        player.calculateLanes(
            scale: globalScale,
            offshoot: (backgroundA.frame.width - view.frame.width) * 0.5, // MARK: Everything should be in unscaled pixel coordinates; is this?
            pad: 18,
            laneWidth: 22,
            laneCount: 3
        )

        // Setup spider
        spider = Spider(
            scale: globalScale,
            texture: tSpider,
            shadow: nil,
            target: self,
            startPos: CGPoint(
                x: frame.midX,
                y: -tSpider.size().height * globalScale
            )
        )
        
        // Setup score keeper
        ScoreKeeper.shared.addLabelToScene(self)
       
        // Setup car spawner
        CarSpawner.shared.configure(
            targetScene: self,
            possibleCars: tCars,
            possibleLanes: player.lanes,
            carShadow: tShadow,
            carSpeed: SpeedKeeper.shared.speed - 30,
            carScale: globalScale * 0.8
        )
        
        // Begin spawning cars
        CarSpawner.shared.start()
        
        // Begin keeping score
        ScoreKeeper.shared.start()
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
        // Play haptic feedback
        hapticFeedback.impactOccurred()
        
        // Change player direction
        player.changeDirection(to: gesture.direction)
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
    
        deltaTime = currentTime - lastUpdateTime as CGFloat // MARK: This starts tweaking when we've left the app for a long time; set it correctly in some sort of callback?

        // Run game functionality here
        scrollBackground()
        player.update(with: deltaTime)
        CarSpawner.shared.updateCars()
        SpeedKeeper.shared.update()
                
        lastUpdateTime = currentTime
    }
}
