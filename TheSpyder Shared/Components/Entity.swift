import SpriteKit
import GameplayKit

// Layers:
// -1 -> BG
//  0 -> Shadows
//  1 -> Cars
//  2 -> Player
//  3 -> GUI
enum GameObjectType: UInt32 {
    case background = 0
    case shadow = 1
    case car = 2
    case player = 3
    case spider = 4
    case gui = 5
}

/// Simple linear interpolation; use with movement!
func lerp(_ start: CGFloat, _ end: CGFloat, _ t: CGFloat) -> CGFloat{
    return (1 - t) * start + t * end
}

class Entity{
    public var type: GameObjectType
    public var node: SKSpriteNode
    public var shadow: SKSpriteNode?

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startRotation: CGFloat = 0){
        self.type = type
       
        // Setup body node and initialize shadow node
        node = SKSpriteNode(texture: texture)
     
        // A shadow may not be given!
        if shadow != nil {
            self.shadow = SKSpriteNode(texture: shadow)
        }

        // Set thieir scale together
        var appliedScale: CGFloat = 1.0
        
        switch type {
        default:
            appliedScale = scale * 0.8
        }

        node.setScale(appliedScale)
        
        if let entityShadow = self.shadow {
            entityShadow.setScale(appliedScale)
        }

        // Finish setting up the node first
        
        // Position & rotate
        node.position = startPos
        node.zPosition = CGFloat(type.rawValue)
        node.zRotation = startRotation
        
        // Setup its physics body
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.categoryBitMask = type.rawValue
    
        switch type {
        case .car:
            node.physicsBody?.contactTestBitMask = 0x1 << 0
        case .player:
            node.physicsBody?.contactTestBitMask = 0x1 << 1
        case .spider:
            node.physicsBody?.contactTestBitMask = 0x1 << 2
        default:
            node.physicsBody?.contactTestBitMask = 0
        }
       
        // Add to scene
        target.addChild(node)
       
        // Now finish configuring and adding the shadow
        if let entityShadow = self.shadow {
            entityShadow.position = node.position
            entityShadow.zPosition = CGFloat(GameObjectType.shadow.rawValue)
            entityShadow.zRotation = node.zRotation
            entityShadow.alpha = 0.2
            
            target.addChild(entityShadow)
        }
    }
 
    /// Keep shadow on the caster
    public func update(){
        if let entityShadow = self.shadow {
            entityShadow.position = node.position
            entityShadow.zRotation = node.zRotation
        }
    }
}
