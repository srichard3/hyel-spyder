import SpriteKit

class Car{
    var entity: Entity
    var smokeParticles: SKEmitterNode
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(
            scale: scale,
            texture: texture,
            shadow: shadow,
            target: target,
            type: GameObjectType.car,
            startPos: startPos
        )
        
        // Give initial velocity
        self.entity.node.physicsBody?.velocity = startVel
        
        // Setup smoke
        self.smokeParticles = SKEmitterNode(fileNamed: "smoke")!
    
        self.smokeParticles.setScale(0.2) // Not very sure how childed particles work so these are eyeball numbers!
        self.smokeParticles.particleBirthRate /= 2 // Make these spawn less
        self.smokeParticles.position.y -= 10

        self.entity.node.addChild(self.smokeParticles)
        
        // No need to make these respond to gamespeed since the only one speeding up is the player
    }
}
