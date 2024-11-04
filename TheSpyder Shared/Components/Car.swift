import SpriteKit

class Car{
    var entity: Entity
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0), startVel: CGVector = CGVector(dx: 0, dy: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.car, startPos: startPos)
        
        // Give start vel
        self.entity.node.physicsBody?.velocity = startVel
    }
    
    public func killIfOffFrame(frame: CGRect){
        // MARK: Before re-adding this, remove Entity first
        /*
        if entity.position.y <= -entity.node.frame.height / 2 {
            car.removeFromParent()
            carsInTheScene.remove(at: i)
        }
           
        else {
            // Any cars on screen should instantly respond to game speed changes, not just newly spawned ones
            let dy: CGFloat = (gameSpeed - 25 * scaleFactor(of: .background)) * deltaTime
            car.position.y -= dy
           
            // Move up!
            i = i + 1
        }
        */
    }
}
