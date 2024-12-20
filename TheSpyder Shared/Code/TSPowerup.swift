import SpriteKit

class TSPowerup{
    var entity: TSEntity
    var particleEffect: SKEmitterNode
    
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
        
        // Give initial velocity
        self.entity.node.physicsBody?.velocity = startVel
        
        // Add particle effect
        self.particleEffect = SKEmitterNode(fileNamed: "glint")!

        self.particleEffect.setScale(0.2) // Eyeballed
        
        // Position at bottom
        self.particleEffect.position.y -= (entity.node.size.height / 2.0) / entity.node.yScale

        self.entity.node.addChild(particleEffect)
    }
}
