import SpriteKit

class TSCar{
    private var entity: TSEntity
    private var smokeParticles: SKEmitterNode
  
    public func getEntity() -> TSEntity {
        return self.entity
    }
    
    public func getNode() -> SKSpriteNode {
        return entity.getNode()
    }
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = TSEntity(
            scale: scale,
            texture: texture,
            shadow: shadow,
            target: target,
            type: TSGameObjectType.car,
            startPos: startPos
        )
   
        // Setup smoke
        self.smokeParticles = SKEmitterNode(fileNamed: "TS_smoke")!
    
        self.smokeParticles.setScale(0.2) // Not very sure how childed particles work so these are eyeball numbers!
        self.smokeParticles.particleBirthRate /= 2 // Make these spawn less
        self.smokeParticles.position.y -= (entity.getNode().size.height / 2) / entity.getNode().yScale // Position at bottom; divide by parent scale to factor it out of this positioning!

        self.getNode().addChild(self.smokeParticles)

        // Give physics body initial velocity
        if let nodePhysicsBody = self.getNode().physicsBody {
            nodePhysicsBody.velocity = startVel
        }
    }
}
