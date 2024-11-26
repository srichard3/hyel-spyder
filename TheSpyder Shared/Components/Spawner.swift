import SpriteKit

/// Handle car spawning
class Spawner{
    static let shared = Spawner()

    var targetScene: SKScene?
    
    var spawnTimer: Timer?
    var spawnInterval: TimeInterval = 0.75
    var spawnIntervalDecrement: CGFloat = 0.05
  
    var spawnChoiceTable = Array<String>()
    var spawnWeights = [
        "car" : 90,
        "horn" : 2,
        "freshener" : 5,
        "drink" : 3
    ]

    var cars = Array<Car>()
    var possibleCars: [SKTexture]?
    var possibleLanes: [CGPoint]?
    var carShadowTexture: SKTexture?
    var carSpeed: CGFloat = 1
    var carScale: CGFloat = 1
  
    var powerups = Array<Powerup>()
    var powerupTextures: Dictionary<String, SKTexture>?
    var powerupScale: CGFloat = 1

    /// Configures the car spawner with the parameters it needs.
    public func configure(targetScene: SKScene, possibleCars: [SKTexture], possibleLanes: [CGPoint], powerupTextures: Dictionary<String, SKTexture>, carShadow: SKTexture?, carSpeed: CGFloat, carScale: CGFloat){
        self.targetScene = targetScene
        self.possibleCars = possibleCars
        self.possibleLanes = possibleLanes
        self.powerupTextures = powerupTextures
        self.carShadowTexture = carShadow
        self.carSpeed = carSpeed
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
        if spawnChoiceTable.isEmpty {
            return
        }
        
        // Choose random lane and spawn a random item on it
        let chosenLane: CGPoint = self.possibleLanes![Int.random(in: 0..<self.possibleLanes!.count)]
        let randomItem = spawnChoiceTable[Int.random(in: 0..<spawnChoiceTable.count)]
      
        // We will either spawn a car or a powerup
        if randomItem == "car" {
            // Create
            let chosenCarTexture: SKTexture = possibleCars![Int.random(in: 0..<possibleCars!.count)]
            let newCar = Car(
                scale: self.carScale,
                texture: chosenCarTexture,
                shadow: carShadowTexture,
                target: targetScene!,
                startPos: CGPoint(x: chosenLane.x, y: targetScene!.frame.height + chosenCarTexture.size().height * carScale),
                startVel: CGVector(dx: 0, dy: -carSpeed)
            )
            
            // Keep track
            cars.append(newCar)
        } else {
            // Same generation pattern here
            let chosenPowerupTexture = powerupTextures![randomItem]
            let newPowerup = Powerup(
                scale: self.carScale,
                texture: chosenPowerupTexture!,
                shadow: carShadowTexture,
                target: targetScene!,
                startPos: CGPoint(x: chosenLane.x, y: targetScene!.frame.height + chosenPowerupTexture!.size().height * carScale),
                startVel: CGVector(dx: 0, dy: -carSpeed)
            )
            
            powerups.append(newPowerup)
        }
    }
    
    /// Begin spawning cars, giving it a set of possible lanes to pick from
    func start(){
        if self.targetScene == nil {
            return
        }
       
        // The target is where the selector is! Make sure the method of #selector is part of target
        spawnTimer = Timer.scheduledTimer(
            timeInterval: spawnInterval,
            target: self,
            selector: #selector(spawnSomething),
            userInfo: nil,
            repeats: true
        )
    }
   
    /// Stop spawning cars
    public func stop(){
        if self.spawnTimer != nil {
            self.spawnTimer?.invalidate()
            self.spawnTimer = nil
        }
    }
   
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
                }
                
                // If not, update it!
                else{
                    currentCar.entity.update()
                    
                    // Make cars respond to velocity changes in real time
                    currentCar.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -carSpeed)
                    
                    i = i + 1
                }
            }
        }
        
        if !powerups.isEmpty {
            var i = 0
            while i < cars.count {
                let currentCar = cars[i]
                
                // Remove car if off screen
                if currentCar.entity.node.position.y <= -currentCar.entity.node.frame.height / 2 {
                    // Remove from scene
                    currentCar.entity.removeFromTarget()
                    
                    // Remove from tracker array, which should mark it for garbage collection
                    cars.remove(at: i)
                }
                
                // If not, update it!
                else{
                    currentCar.entity.update()
                    
                    // Make cars respond to velocity changes in real time
                    currentCar.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -carSpeed)
                    
                    i = i + 1
                }
            }
        }
    }
}
