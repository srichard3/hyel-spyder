import SpriteKit

class Car{
    var entity: Entity
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.car, startPos: startPos)
        
        // Give start vel
        self.entity.node.physicsBody?.velocity = startVel
    }
   
    /// Remove this car object from the screen
    public func killIfOffFrame(frame: CGRect){
        if entity.node.position.y <= -entity.node.frame.height / 2 {
            entity.node.removeFromParent()
            entity.shadow!.removeFromParent() // All cars have shadows so this unwrap is ok
         }
    }
}
