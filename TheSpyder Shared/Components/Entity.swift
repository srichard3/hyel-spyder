import SpriteKit
import GameplayKit

enum GameObjectType: UInt32 {
    case background = 0
    case shadow = 1
    case car = 2
    case player = 3
    case spider = 4
    case gui = 5
}

/// Simple linear interpolation; use with movement!
func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat{
    return (1 - t) * start + t * end
}

class Entity{
    public var type: GameObjectType
    public var node: SKSpriteNode
    public var shadow: SKSpriteNode

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startRotation: CGFloat = 0){
        self.type = type
       
        // Setup body node
        node = SKSpriteNode(texture: texture)
     
        // Set its scale
        switch type {
        default:
            node.setScale(scale * 0.8)
        }
        
        // Layers:
        // -1 -> BG
        //  0 -> Shadows
        //  1 -> Cars
        //  2 -> Player
        //  3 -> GUI
        node.zPosition = CGFloat(type.rawValue)
        
        // Position & rotate
        node.position = startPos
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

        // Setup shadow node
        self.shadow = SKSpriteNode(texture: shadow)

        self.shadow.zPosition = CGFloat(GameObjectType.shadow.rawValue)
        self.shadow.alpha = 0.2

        target.addChild(self.shadow)
    }
 
    /// Keep shadow on the caster
    public func update(){
        shadow.position = node.position
        shadow.zRotation = node.zRotation
    }
}
