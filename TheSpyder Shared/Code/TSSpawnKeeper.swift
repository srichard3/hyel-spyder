import SpriteKit

/// Handle car spawning
class TSSpawnKeeper{
    public static let shared = TSSpawnKeeper()
    
    /* Guaranteed Attributes */
   
    private let baseSpawnInterval = 0.75
    private var spawnInterval = 0.75 // Should match base value!
    
    private let spawnIntervalSubdivisor = 1.3 // Spawn interval gets subdivided by this amount every speedup cycle

    private var cars = Array<TSCar>()
    private var powerups = Array<TSPowerup>()

    private var carScale = 1.0 // MARK: Why is this here???
    private var powerupScale = 1.0 // MARK: ???

    private var spawnWeights: Dictionary<TSGameObjectType, Int> = [
        .car : 100,
        .horn : 3,
        .drink : 2,
        .freshener : 3
    ]

    /* Unknown Attributes */

    private var targetScene: SKScene?

    private var spawnChoiceTable: [TSGameObjectType]?

    private var carShadowTexture: SKTexture? // MARK: Why on earth is this here??? Who wrote this???

    private var possibleCars: [SKTexture]?
    private var possibleLanes: [CGPoint]?
    private var possiblePowerupsTextures: Dictionary<TSGameObjectType, SKTexture>?

    private var spawnTimer: Timer?
    
    public func configure(targetScene: SKScene, possibleCars: [SKTexture], possibleLanes: [CGPoint], powerupTextures: Dictionary<TSGameObjectType, SKTexture>, carShadow: SKTexture?, carScale: CGFloat){
        self.targetScene = targetScene
        self.possibleCars = possibleCars
        self.possibleLanes = possibleLanes
        self.possiblePowerupsTextures = powerupTextures
        self.carShadowTexture = carShadow
        self.carScale = carScale
     
        // Add each item (weight) times to the choice table
        // We will then simlpy pick an item from this resulting table!
        spawnChoiceTable = []
        if spawnChoiceTable!.isEmpty {
            for (item, weight) in spawnWeights {
                for _ in 0...weight {
                    spawnChoiceTable!.append(item)
                }
            }
        }
    }
  
    public func subdivideSpawnInterval(){
        // Change the spawn interval
        self.spawnInterval /= self.spawnIntervalSubdivisor
        
        // Restart the timer to reflect those changes
        self.stopTimer()
        self.startTimer()
        
        
        print("--'d spawn interval, new: \(self.spawnInterval)")
    }
    
    public func resetSpawnInterval(){
        self.spawnInterval = baseSpawnInterval
    }
    
    /// Spawns either a car or power-up on a random lane
    @objc func spawnSomething(){
        if let scene = self.targetScene, let spawnChoiceTable = self.spawnChoiceTable {
            // Need a weight table to know what to spawn!
            if spawnChoiceTable.isEmpty {
                return
            }
            
            // Choose random lane and spawn a random item on it
            let randomLane: CGPoint = self.possibleLanes![Int.random(in: 0..<self.possibleLanes!.count)]
            let randomItemType = spawnChoiceTable[Int.random(in: 0..<spawnChoiceTable.count)]
       
            // Spawn a car
            if randomItemType == TSGameObjectType.car {
                let chosenCarTexture: SKTexture = possibleCars![Int.random(in: 0..<possibleCars!.count)]
                let newCar = TSCar(
                    scale: self.carScale,
                    texture: chosenCarTexture,
                    shadow: carShadowTexture,
                    target: scene,
                    startPos: CGPoint(x: randomLane.x, y: scene.frame.height + chosenCarTexture.size().height * carScale),
                    startVel: CGVector(dx: 0, dy: -TSSpeedKeeper.shared.getCarSpeed())
                )
                
                cars.append(newCar)
            // Spawn a power-up
            } else {
                if let possiblePowerupsTextures = self.possiblePowerupsTextures {
                    // If the chosen random type doesn't exist in our powerup table, then something's gone wrong!
                    if !possiblePowerupsTextures.keys.contains(randomItemType) {
                        print("tried to spawn illegal item type \(randomItemType)!")
                        return
                    }
                   
                    // Pick the random texture and spawn the powerup
                    if let chosenPowerupTexture = possiblePowerupsTextures[randomItemType] {
                        let newPowerup = TSPowerup(
                            scale: self.carScale,
                            texture: chosenPowerupTexture,
                            target: scene,
                            type: randomItemType,
                            startPos: CGPoint(x: randomLane.x, y: scene.frame.height + chosenPowerupTexture.size().height * carScale),
                            startVel: CGVector(dx: 0, dy: -TSSpeedKeeper.shared.getCarSpeed())
                        )
                        
                        powerups.append(newPowerup)
                    }
                }
            }
        }
    }
    
    func startTimer(){
        // Start spawn timer
        if self.spawnTimer == nil {
            spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { timer in
                self.spawnSomething()
            }
        }
    }
   
    public func stopTimer(){
        // Stop spawn timer
        if self.spawnTimer != nil {
            self.spawnTimer?.invalidate()
            self.spawnTimer = nil
        }
    }
  
    /// Clear everything the spawner is responsible for
    public func clearState(){
        // Detach all powerups and cars from parent scene
        for car in cars {
            car.getEntity().removeFromTarget()
        }
     
        for powerup in powerups {
            powerup.getEntity().removeFromTarget()
        }
        
        // Then clear all from tracked active list
        cars.removeAll()
        powerups.removeAll()
    }

    public func clearCars(){
        for car in cars {
            car.getEntity().removeFromTarget()
        }

        cars.removeAll()
    }
    
    /// Removes a power-up with a matching sprite node
    public func removePowerup(with spriteNode: SKSpriteNode){
        var i = 0
        while i < powerups.count {
            let currentPowerup = powerups[i]
            if spriteNode == currentPowerup.getNode() {
                currentPowerup.getEntity().removeFromTarget()
                powerups.remove(at: i)
                return
            } else {
                i += 1
            }
        }
    }
  
    /// Removes a powerup specified by its own object
    public func removePowerup(target: TSPowerup){
        var i = 0
        while i < powerups.count {
            let currentPowerup = powerups[i]
            if currentPowerup.getNode() == target.getNode() {
                currentPowerup.getEntity().removeFromTarget()
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
                if currentCar.getNode().position.y <= -currentCar.getNode().frame.height / 2 {
                    // Remove from scene
                    currentCar.getEntity().removeFromTarget()
                    
                    // Remove from tracker array, which should mark it for garbage collection
                    cars.remove(at: i)
                // Otherwise, update it only
                } else {
                    // Make cars respond to velocity changes in real time
                    if let currentCarPhysicsBody = currentCar.getNode().physicsBody {
                        currentCarPhysicsBody.velocity = CGVector(dx: 0, dy: -TSSpeedKeeper.shared.getCarSpeed())
                    }
                    
                    i = i + 1
                }
            }
        }
       
        // Same update pattern here
        if !powerups.isEmpty {
            var i = 0
            while i < powerups.count {
                let currentPowerup = powerups[i]
                if currentPowerup.getNode().position.y <= -currentPowerup.getNode().frame.height / 2 {
                    currentPowerup.getEntity().removeFromTarget()
                    powerups.remove(at: i)
                } else {
                    if let currentPowerupPhysicsBody = currentPowerup.getNode().physicsBody {
                        currentPowerupPhysicsBody.velocity = CGVector(dx: 0, dy: -TSSpeedKeeper.shared.getCarSpeed())
                    }
                    
                    i += 1
                }
            }
        }
    }
}
