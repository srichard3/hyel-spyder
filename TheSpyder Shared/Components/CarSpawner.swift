import SpriteKit

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
