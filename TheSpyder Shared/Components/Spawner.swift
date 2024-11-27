import SpriteKit

/// Handle car spawning
class Spawner{
    static let shared = Spawner()

    var targetScene: SKScene?
    
    var spawnTimer: Timer?
    var spawnInterval: TimeInterval = 0.75
    var spawnIntervalDecrement: CGFloat = 0.05
  
    var spawnChoiceTable = Array<GameObjectType>()
    var spawnWeights: Dictionary<GameObjectType, Int> = [
        .car : 90,
        .horn : 2,
        .drink : 5,
        .freshener : 5000
    ]

    var cars = Array<Car>()
    var possibleCars: [SKTexture]?
    var possibleLanes: [CGPoint]?
    var carShadowTexture: SKTexture?
    var carScale: CGFloat = 1
  
    var powerups = Array<Powerup>()
    var powerupTextures: Dictionary<GameObjectType, SKTexture>?
    var powerupScale: CGFloat = 1
    
    var speed: CGFloat = 1

    /// Configures the car spawner with the parameters it needs.
    public func configure(targetScene: SKScene, possibleCars: [SKTexture], possibleLanes: [CGPoint], powerupTextures: Dictionary<GameObjectType, SKTexture>, carShadow: SKTexture?, carSpeed: CGFloat, carScale: CGFloat){
        self.targetScene = targetScene
        self.possibleCars = possibleCars
        self.possibleLanes = possibleLanes
        self.powerupTextures = powerupTextures
        self.carShadowTexture = carShadow
        self.speed = carSpeed
        self.carScale = carScale
     
        // Add each item (weight) times to the choice table
        // We will then simlpy pick an item from this resulting table!
        if spawnChoiceTable.isEmpty {
            spawnChoiceTable = []
            for (item, weight) in spawnWeights {
                for _ in 0...weight {
                    spawnChoiceTable.append(item)
                }
            }
        }
    }
    
    @objc func spawnSomething(){
        if let scene = self.targetScene {
            if spawnChoiceTable.isEmpty {
                return
            }
            
            // Choose random lane and spawn a random item on it
            let chosenLane: CGPoint = self.possibleLanes![Int.random(in: 0..<self.possibleLanes!.count)]
            let randomItem = spawnChoiceTable[Int.random(in: 0..<spawnChoiceTable.count)]
        
            // We will either spawn a car...
            if randomItem == GameObjectType.car {
                let chosenCarTexture: SKTexture = possibleCars![Int.random(in: 0..<possibleCars!.count)]
                let newCar = Car(
                    scale: self.carScale,
                    texture: chosenCarTexture,
                    shadow: carShadowTexture,
                    target: scene,
                    startPos: CGPoint(x: chosenLane.x, y: scene.frame.height + chosenCarTexture.size().height * carScale),
                    startVel: CGVector(dx: 0, dy: -speed)
                )
                
                cars.append(newCar)
            // Or a powerup
            } else {
                let chosenPowerupTexture = powerupTextures![randomItem]
                let newPowerup = Powerup(
                    scale: self.carScale,
                    texture: chosenPowerupTexture!,
                    shadow: carShadowTexture,
                    target: scene,
                    type: randomItem,
                    startPos: CGPoint(x: chosenLane.x, y: scene.frame.height + chosenPowerupTexture!.size().height * carScale),
                    startVel: CGVector(dx: 0, dy: -speed)
                )
                
                powerups.append(newPowerup)
            }
        }
    }
    
    /// Start spawner
    func start(){
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { timer in
            self.spawnSomething()
        }
    }
   
    /// Stop spawner
    public func stop(){
        if self.spawnTimer != nil {
            self.spawnTimer?.invalidate()
            self.spawnTimer = nil
        }
    }
  
    /// Clear everything the spawner is responsible for
    public func clear(){
        // Detach all powerups and cars from parent scene
        for car in cars {
            car.entity.removeFromTarget()
        }
     
        for powerup in powerups {
            powerup.entity.removeFromTarget()
        }
        
        // Then clear all from tracked active list
        cars.removeAll()
        powerups.removeAll()
    }
    
    public func update(){
        if !cars.isEmpty {
            var i = 0
            while i < cars.count {
                let currentCar = cars[i]
                
                // Remove car if off screen
                if currentCar.entity.node.position.y <= -currentCar.entity.node.frame.height / 2 {
                    // Remove from scene
                    currentCar.entity.removeFromTarget()
                    
                    // Remove from tracker array, which should mark it for garbage collection
                    cars.remove(at: i)
                // Otherwise, update it only
                } else {
                    currentCar.entity.update()
                    
                    // Make cars respond to velocity changes in real time
                    currentCar.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -speed)
                    
                    i = i + 1
                }
            }
        }
       
        // Same update pattern here
        if !powerups.isEmpty {
            var i = 0
            while i < cars.count {
                let currentPowerup = powerups[i]
                if currentPowerup.entity.node.position.y <= -currentPowerup.entity.node.frame.height / 2 {
                    currentPowerup.entity.removeFromTarget()
                    powerups.remove(at: i)
                } else {
                    currentPowerup.entity.update()
                    currentPowerup.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -speed)
                    i += 1
                }
            }
        }
    }
}
