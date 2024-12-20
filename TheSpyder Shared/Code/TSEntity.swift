import SpriteKit
import GameplayKit

enum TSGameObjectType: UInt32 {
    case background = 0
    case shadow = 1
    case car = 2
    case horn = 3
    case freshener = 4
    case drink = 5
    case player = 6
    case spider = 7
    case gui = 8
}

let smoothTime: CGFloat = 7.5

class TSEntity{
    private var type: TSGameObjectType
    private var node: SKSpriteNode
    private var shadow: SKSpriteNode?

    public func getType() -> TSGameObjectType {
        return type;
    }
   
    public func getNode() -> SKSpriteNode {
        return node;
    }
   
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, type: TSGameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startRotation: CGFloat = 0){
        self.type = type
       
        // Setup body node
        node = SKSpriteNode(texture: texture)
        
        node.setScale(scale)
        node.position = startPos
        node.zPosition = CGFloat(type.rawValue)
        node.zRotation = startRotation
        
        // Setup body node physics body
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.categoryBitMask = type.rawValue
        node.physicsBody?.contactTestBitMask = TSEntity.contactTestFor(type)

        target.addChild(node)

        // Set up shadow, note one might not be given!
        self.shadow = SKSpriteNode(texture: shadow) // A shadow may not be given!
        if let entityShadow = self.shadow {
            entityShadow.alpha = 0.2
            entityShadow.zPosition = CGFloat(TSGameObjectType.shadow.rawValue)
            
            node.addChild(entityShadow)
        }
    }
    
    /// Get the appropriate contact test bitmask of the given game object type
    public static func contactTestFor(_ type: TSGameObjectType) -> UInt32 {
        switch type {
        case .player:
            return TSGameObjectType.car.rawValue | TSGameObjectType.spider.rawValue
        default:
            return 0
        }
    }
   
    /// Get the category bitmask of a game object type
    public static func categoryBitmaskOf(_ type: TSGameObjectType) -> UInt32 {
        return type.rawValue
    }
    
    // Remove body and shadow nodes from the parent
    public func removeFromTarget(){
        node.removeFromParent()
        if let shadow = self.shadow {
            shadow.removeFromParent()
        }
    }
}
