import SpriteKit

/// Singleton; keeps track of the player's score
class TSScoreKeeper{
    static let shared = TSScoreKeeper()
   
    var targetScene: SKScene?
    
    var score: Int = 0

    var baseAward: Int = 5
    var awardTimer: Timer!
    var awardInterval: TimeInterval = 1

    var multiplier: CGFloat = 1.0
    var multiplierIncrement: CGFloat = 0.25
    
    var label: SKLabelNode!
    private var backingLabels = Array<SKLabelNode>()
 
    /// Use this when setting the label text
    private func setLabelText(_ text: String){
        // Update main label's text
        self.label.text = text
        
        // Make the backing labels' text match the main label's text
        for label in self.backingLabels {
            label.text = self.label.text
        }
    }
    
    /// Adds the score label to the target scene
    public func configureLabel(_ target: SKScene){
        // Setup score label
        self.label = SKLabelNode(text: "\(self.score)")

        // Position label using scene dimensions
        self.label.position = CGPoint(x: target.frame.midX, y: target.frame.midY + target.frame.midY / 2)

        self.label.fontName = "FFF Forward" // Use the name of the font, not the file name
        self.label.fontColor = UIColor(cgColor: CGColor(gray: 0.8, alpha: 1))
        self.label.fontSize = 32
        self.label.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
     
        // Add to target scene
        target.addChild(self.label)

        // Now set up 4-way labels
        self.backingLabels.removeAll()
       
        // God forbid the following code...
        
        for _ in 0..<4 {
            // This forcecast should be fine since the main label is also a SKLabelNode
            let newLabel = self.label.copy() as! SKLabelNode
    
            // Make these labels contrast the main one and go behind
            newLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.1, alpha: 1))
            newLabel.zPosition = self.label.zPosition - 1
        
            // Add label to tracker array
            self.backingLabels.append(newLabel)
            
            // And to scene
            target.addChild(newLabel)
        }
      
        // Offset each label to create the desired effect
        let backingLabelOffset = 6.0
       
        self.backingLabels[0].position.x -= backingLabelOffset
        self.backingLabels[1].position.x += backingLabelOffset
        self.backingLabels[2].position.y -= backingLabelOffset
        self.backingLabels[3].position.y += backingLabelOffset
    }
 
    /// Hide and unhide all of label
    public func hideLabel(){
        self.label.isHidden = true
        for label in self.backingLabels {
            label.isHidden = true
        }
    }
   
    public func unhideLabel(){
        self.label.isHidden = false
        for label in self.backingLabels {
            label.isHidden = false
        }
    }
    
    /// Add current score award times multiplier and update score label to reflect it
    @objc func addScore(){
        score += Int(CGFloat(baseAward) * multiplier)
        setLabelText("\(score)")
    }

    /// Start keeping score
    public func start(){
        awardTimer = Timer.scheduledTimer(
            timeInterval: awardInterval,
            target: self,
            selector: #selector(addScore),
            userInfo: nil,
            repeats: true
        )
    }

    /// Stop keeping score
    public func stop(){
        if self.awardTimer != nil {
            self.awardTimer?.invalidate()
            self.awardTimer = nil
        }
    }
   
    /// Reset state
    public func reset(){
        // Stop timer
        self.stop()
       
        // Reset score and multiplier
        score = 0
        multiplier = 1

        // Set the score label accordingly
        setLabelText("\(score)")
    }
}
