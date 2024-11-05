import SpriteKit

class Player{
    var entity: Entity
    var lanes = Array<CGPoint>()
    var lane: Int = 0

    var targetPos: CGPoint
    var targetRot: CGFloat
    var smoothTime: CGFloat
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, startPos: CGPoint = CGPoint(x: 0, y: 0)){
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.player, startPos: startPos)
        
        targetPos = CGPoint(x: 0, y: 0)
        targetRot = 0
        smoothTime = 7.5
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
        
        // Put the player at the middle lane
        lane = self.lanes.count / 2 as Int
    }

    /// Try to move to the lane in the given direction
    public func changeDirection(to dir: UISwipeGestureRecognizer.Direction){
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
  
    private func rotationEffect(){
        // No move effect possible if there's no defined places to move towards
        if lanes.count == 0 {
            return;
        }
        
        // Take a small fraction of the inverted remaining distance to the target lane to rotate the player node a bit when moving it
    }
  
    /// Move the player node using interpolation instead of its physics body
    private func lerpMove(with deltaTime: CGFloat){
        if lanes.isEmpty {
            return
        }
        
        targetPos.x = lanes[lane].x
        targetPos.y = lanes[lane].y
        
        entity.node.position.x = lerp(entity.node.position.x, targetPos.x, smoothTime * deltaTime)
        entity.node.position.y = lerp(entity.node.position.x, targetPos.y, smoothTime * deltaTime)
       
        // Add some rotation
        let xDistanceToLane: CGFloat = lanes[lane].x - entity.node.position.x
        entity.node.zRotation = lerp(entity.node.zRotation, xDistanceToLane * 0.0125, smoothTime * deltaTime)
    }

    public func update(with deltaTime: CGFloat){
        entity.update()
        lerpMove(with: deltaTime)
    }
}
