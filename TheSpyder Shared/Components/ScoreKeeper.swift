import SpriteKit

/// Singleton; keeps track of the player's score
class ScoreKeeper{
    static let shared = ScoreKeeper()
    
    var score: Int = 0

    var baseAward: Int = 5
    var awardTimer: Timer!
    var awardInterval: TimeInterval = 1

    var multiplier: CGFloat = 1.0
    var multiplierIncrement: CGFloat = 0.25
    
    var label: SKLabelNode
 
    // Private initializers prevent external instantiation! Useful for singletons
    private init(){
        // Setup score label
        self.label = SKLabelNode(text: "\(self.score)")

        self.label.fontName = "FFF Forward" // Use the name of the font, not the file name
        self.label.fontSize = 32
        self.label.zPosition = CGFloat(GameObjectType.gui.rawValue)
    }
    
    public func addLabelToScene(_ target: SKScene){
        // Add to target scene
        target.addChild(label)
      
        // Position label using scene dimensions
        self.label.position = CGPoint(x: target.frame.midX, y: target.frame.midY + target.frame.midY / 2)
    }
   
    @objc func addScore(){
        score += Int(CGFloat(baseAward) * multiplier)
        label.text = "\(score)"
    }

    /// Start keeping score
    public func start(){
       
    }
  
    /// Stop keeping score
    public func stop(){
        
    }
}
