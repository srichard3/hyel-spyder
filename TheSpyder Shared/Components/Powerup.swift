import SpriteKit

class Powerup{
    var entity: Entity
    var particleEffect: SKEmitterNode
    
    init(scale: CGFloat, texture: SKTexture, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(
            scale: scale,
            texture: texture,
            shadow: nil,
            target: target,
            type: type,
            startPos: startPos
        )
        
        // Give initial velocity
        self.entity.node.physicsBody?.velocity = startVel
        
        // Add particle effect
        particleEffect = SKEmitterNode(fileNamed: "glint")!

        self.entity.node.addChild(particleEffect)

        particleEffect.setScale(0.2) // Eyeballed
        particleEffect.position.y -= 7 // Eyeballed
    }
}
