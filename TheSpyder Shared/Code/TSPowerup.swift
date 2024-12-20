import SpriteKit

class TSPowerup{
    private var entity: TSEntity
    private var sparkleParticles: SKEmitterNode
  
    public func getEntity() -> TSEntity {
        return self.entity
    }

    public func getNode() -> SKSpriteNode {
        return self.entity.getNode()
    }
    
    init(scale: CGFloat, texture: SKTexture, target: SKScene, type: TSGameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = TSEntity(
            scale: scale,
            texture: texture,
            shadow: nil,
            target: target,
            type: type,
            startPos: startPos
        )

        // Setup particle
        self.sparkleParticles = SKEmitterNode(fileNamed: "glint")!
      
        self.sparkleParticles.setScale(0.2) // Eyeballed
        self.sparkleParticles.position.y -= (self.getNode().size.height / 2.0) / self.getNode().yScale // Position at bottom

        self.entity.getNode().addChild(sparkleParticles)

        // Give physics body start vel
        if let nodePhysicsBody = self.getNode().physicsBody {
            nodePhysicsBody.velocity = startVel
        }
    }
}
