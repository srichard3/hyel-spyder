import SpriteKit

class Player{
    var entity: Entity
    var lanes = Array<CGPoint>()
    var lane: Int = 0

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.player, startPos: startPos)
    }
   
    /// Calculate position points the player can switch to
    public func calculateLanes(scale: CGFloat, offshoot: CGFloat, pad: CGFloat, laneWidth: CGFloat, laneCount: Int){
        // Clear any previous lane info
        lanes.removeAll();
       
        // Compute new lanes
        // Example lane calculations:
        // lane 0 = 18 + 11
        // lane 1 = 18 + 22 + 10
        // lane 3 = 18 + 22 + 22 + 9
        // ...
        for i in stride(from: 0, to: laneCount, by: 1) {
            let t = CGFloat(i)
            
            let laneX = (pad + (t * laneWidth) + (laneWidth / 2 - t)) * scale - offshoot
            let laneY = self.entity.node.position.y
            
            lanes.append(CGPoint(x: laneX, y: laneY))
        }
    }

    /// Try to move to the lane in the given direction
    public func move(towards dir: UISwipeGestureRecognizer.Direction){
        switch dir {
        case .left:
            if lane - 1 >= 0 {
                lane -= 1
            }
        case.right:
            if lane + 1 <= lanes.count - 1 {
                lane += 1
            }
        default:
            return
        }
    }
  
    private func moveEffect(){
        // No move effect possible if there's no defined places to move towards
        if lanes.count == 0 {
            return;
        }
        
        // Take a small fraction of the inverted remaining distance to the target lane to rotate the player node a bit when moving it
        let xTargetLaneDistance = lanes[lane].x - entity.node.position.x
        entity.node.zRotation = -xTargetLaneDistance * 0.0125
    }
    
    public func update(){
        entity.update()
    }
}
