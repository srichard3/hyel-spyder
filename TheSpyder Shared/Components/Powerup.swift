import SpriteKit

class Powerup{
    var entity: Entity
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.car, startPos: startPos)
        
        // Give initial velocity
        self.entity.node.physicsBody?.velocity = startVel
    }
}
