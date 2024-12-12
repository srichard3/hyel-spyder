import SpriteKit

/// Handle car spawning
class Spawner{
    public static let shared = Spawner()

    private var targetScene: SKScene?
    
    private var spawnTimer: Timer?
    private var spawnInterval = 0.75
    private var spawnIntervalDecrement = 0.05
  
    private var spawnChoiceTable = Array<GameObjectType>()
    private let powerupSpawnBoost = 5
    private var spawnWeights: Dictionary<GameObjectType, Int> = [
        .car : 95,
        .horn : 1 * 5,
        .drink : 2 * 5,
        .freshener : 1 * 5
    ]

    private var cars = Array<Car>()
    private var possibleCars: [SKTexture]?
    private var possibleLanes: [CGPoint]?
    private var carShadowTexture: SKTexture?
    private var carScale = 1.0
  
    private var powerups = Array<Powerup>()
    private var powerupTextures: Dictionary<GameObjectType, SKTexture>?
    private var powerupScale = 1.0
    
    public func configure(targetScene: SKScene, possibleCars: [SKTexture], possibleLanes: [CGPoint], powerupTextures: Dictionary<GameObjectType, SKTexture>, carShadow: SKTexture?, carScale: CGFloat){
        self.targetScene = targetScene
        self.possibleCars = possibleCars
        self.possibleLanes = possibleLanes
        self.powerupTextures = powerupTextures
        self.carShadowTexture = carShadow
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
  
    public func incrementSpawnInterval(){
        self.spawnInterval += self.spawnIntervalDecrement
    }
    
    public func decrementSpawnInterval(){
        self.spawnInterval -= self.spawnIntervalDecrement
    }
    
    public func resetSpawnInterval(){
        self.spawnInterval = 0.75
    }
    
    /// Spawns either a car or power-up on a random lane
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
                    startVel: CGVector(dx: 0, dy: -SpeedKeeper.shared.getCarSpeed())
                )
                
                cars.append(newCar)
            // Or a powerup
            } else {
                let chosenPowerupTexture = powerupTextures![randomItem]
                let newPowerup = Powerup(
                    scale: self.carScale,
                    texture: chosenPowerupTexture!,
                    target: scene,
                    type: randomItem,
                    startPos: CGPoint(x: chosenLane.x, y: scene.frame.height + chosenPowerupTexture!.size().height * carScale),
                    startVel: CGVector(dx: 0, dy: -SpeedKeeper.shared.getCarSpeed())
                )
                
                powerups.append(newPowerup)
            }
        }
    }
    
    func start(){
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { timer in
            self.spawnSomething()
        }
    }
   
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

    public func clearCars(){
        for car in cars {
            car.entity.removeFromTarget()
        }

        cars.removeAll()
    }
    
    /// Removes a power-up with a matching sprite node
    public func removePowerup(with spriteNode: SKSpriteNode){
        var i = 0
        while i < powerups.count {
            let currentPowerup = powerups[i]
            if spriteNode == currentPowerup.entity.node {
                currentPowerup.entity.removeFromTarget()
                powerups.remove(at: i)
                return
            } else {
                i += 1
            }
        }
    }
  
    /// Removes a powerup specified by its own object
    public func removePowerup(target: Powerup){
        var i = 0
        while i < powerups.count {
            let currentPowerup = powerups[i]
            if currentPowerup.entity.node == target.entity.node {
                currentPowerup.entity.removeFromTarget()
                powerups.remove(at: i)
                return
            } else {
                i += 1
            }
        }
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
                    currentCar.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -SpeedKeeper.shared.getCarSpeed())
                    
                    i = i + 1
                }
            }
        }
       
        // Same update pattern here
        if !powerups.isEmpty {
            var i = 0
            while i < powerups.count {
                let currentPowerup = powerups[i]
                if currentPowerup.entity.node.position.y <= -currentPowerup.entity.node.frame.height / 2 {
                    currentPowerup.entity.removeFromTarget()
                    powerups.remove(at: i)
                } else {
                    currentPowerup.entity.update()
                    currentPowerup.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -SpeedKeeper.shared.getCarSpeed())
                    i += 1
                }
            }
        }
    }
}
