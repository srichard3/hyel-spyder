import SpriteKit

class TSPlayer{
    private var entity: TSEntity
    private var lanes = Array<CGPoint>()
    private var lane: Int = 0

    private var targetPos: CGPoint
    private var targetRot: CGFloat
   
    private var isFrozen = false
    
    private var smokeParticles: SKEmitterNode
    private var baseSmokeParticleSpeed: CGFloat
   
    public func getNode() -> SKSpriteNode {
        return self.entity.getNode()
    }

    public func getLanes() -> [CGPoint] {
        return self.lanes
    }
   
    public func freeze() {
        self.isFrozen = true
    }
   
    public func unfreeze() {
        self.isFrozen = false
    }
  
    public func getFrozen() -> Bool {
        return self.isFrozen
    }

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, smokeParticles: SKEmitterNode, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0)){
        // Set up entity
        self.entity = TSEntity(scale: scale, texture: texture, shadow: shadow, target: target, type: TSGameObjectType.player, startPos: startPos)
       
        // Use precise collision
        self.entity.getNode().physicsBody?.usesPreciseCollisionDetection = true
 
        // Initialize interpolation movement stuff
        self.targetPos = CGPoint(x: 0, y: 0)
        self.targetRot = 0

        // Setup smoke
        self.smokeParticles = smokeParticles
    
        // Cache the speed set in the particle editor
        self.baseSmokeParticleSpeed = self.smokeParticles.particleSpeed
        
        self.smokeParticles.setScale(0.3) // Not very sure how childed particles work so these are eyeball numbers!
        self.smokeParticles.position.y -= 10
        self.smokeParticles.targetNode = target

        self.entity.getNode().addChild(self.smokeParticles)
    }

    public func update(with deltaTime: CGFloat){
        // No modifying state if frozen
        if self.isFrozen {
            return
        }

        self.lerpMove(with: deltaTime) // Must update player position before shadow's position is updated!
        self.smokeParticles.particleSpeed = self.baseSmokeParticleSpeed * CGFloat(TSSpeedKeeper.shared.getSpeed()) * 0.01 // The last factor is eyeballed
    }

    /// Calculate position points the player can switch to
    public func calculateLanes(scale: CGFloat, offshoot: CGFloat, pad: CGFloat, laneWidth: CGFloat, laneCount: Int){
        // Clear any previous lane info
        self.lanes.removeAll();
       
        // Compute new lanes
        // Example lane calculations:
        // lane 0 = 18 + 11
        // lane 1 = 18 + 22 + 10
        // lane 3 = 18 + 22 + 22 + 9
        // ...
        
        for i in stride(from: 0, to: laneCount, by: 1) {
            let t = CGFloat(i)
            
            let laneX = (pad + (t * laneWidth) + (laneWidth / 2 - t)) * scale - offshoot
            let laneY = self.getNode().position.y
            
            self.lanes.append(CGPoint(x: laneX, y: laneY))
        }
        
        // Put the player at the middle lane
        self.lane = self.lanes.count / 2 as Int
    }

    /// Try to move to the lane in the given direction
    public func changeDirection(to dir: UISwipeGestureRecognizer.Direction){
        // No modifying state if frozen
        if self.isFrozen {
            return
        }

        if dir == .left && self.lane - 1 >= 0 {
            self.lane -= 1
        } else if (dir == .right && self.lane + 1 <= self.lanes.count - 1) {
            self.lane += 1
        }
    }

    public func clearState(){
        // No modifying state if frozen
        if self.isFrozen {
            return
        }
        
        if self.lanes.isEmpty {
            return
        }
   
        // Set current lane to centermost
        self.lane = self.lanes.count / 2 as Int
       
        // Set the target pos to that lane, and clear rotation
        self.targetPos.x = self.lanes[lane].x
        self.targetPos.y = self.lanes[lane].y
        self.targetRot = 0
    
        // Sync with transform values for instant reset
        self.getNode().position.x = targetPos.x
        self.getNode().position.y = targetPos.y
        self.getNode().zRotation = 0
    }
    
    /// Move the player node using interpolation instead of its physics body
    private func lerpMove(with deltaTime: CGFloat){
        // No modifying state if frozen
        if self.isFrozen {
            return
        }
        
        if lanes.isEmpty {
            return
        }
       
        targetPos.x = lanes[lane].x
        targetPos.y = lanes[lane].y
        
        self.getNode().position.x = TSMath.lerp(self.getNode().position.x, targetPos.x, smoothTime * deltaTime)
        self.getNode().position.y = TSMath.lerp(self.getNode().position.y, targetPos.y, smoothTime * deltaTime)
       
        // Add some rotation
        let xDistanceToLane: CGFloat = lanes[lane].x - self.getNode().position.x
        self.getNode().zRotation = TSMath.lerp(self.getNode().zRotation, -xDistanceToLane * 0.0125, smoothTime * deltaTime)
    }
}
