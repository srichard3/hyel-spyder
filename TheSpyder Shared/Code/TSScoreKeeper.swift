import SpriteKit

/// Singleton; keeps track of the player's score
class TSScoreKeeper{
    static let shared = TSScoreKeeper()
 
    /* Guaranteed Attributes */
    
    private var baseScoreAward = 5
    private var score = 0
    private var lastScore = 0
    private var highScore = 0
   
    private let baseAwardInterval = 1.0
    private var awardInterval = 1.0 // Should match base value!

    private var multiplier = 1.0
   
    private let baseMultiplierIncrement = 0.25
    private var multiplierIncrement = 0.25 // Should match base value!

    /* Nullable Attributes */

    private var targetScene: SKScene?
   
    private var awardTimer: Timer?

    private var label: SKLabelNode?
    private var labelBg: [SKLabelNode]?

    private func setLabelText(to text: String){
        if let label = self.label {
            // Update main label's text
            label.text = text
            
            // Update bg. labels' text
            if let bgLabels = self.labelBg {
                for bgLabel in bgLabels {
                    bgLabel.text = label.text
                }
            }
        }
    }

    public func getCurrentScore() -> Int {
        return self.score
    }
  
    public func getLastScore() -> Int {
        return self.lastScore
    }
   
    public func getHighScore() -> Int {
        return self.highScore
    }
    
    public func getLabelPosition() -> CGPoint? {
        return self.label?.position
    }
   
    public func configureLabel(_ target: SKScene){
        // Make values match base
        awardInterval = baseAwardInterval
        multiplierIncrement = baseMultiplierIncrement
        
        // Setup score label
        self.label = SKLabelNode(text: "\(self.score)")
        if let label = self.label {
            label.fontName = "FFF Forward"
            label.fontColor = UIColor(cgColor: CGColor(gray: 0.8, alpha: 1))
            label.fontSize = 32
            label.position = CGPoint(x: target.frame.midX, y: target.frame.midY + target.frame.midY / 2) // Position label using scene dimensions
            label.zPosition = CGFloat(TSGameObjectType.gui.rawValue)
            
            target.addChild(label)
            
            if self.labelBg != nil {
                self.labelBg!.removeAll()
            } else {
                self.labelBg = []
            }
     
            /* The background of a label is just 4 more labels
             * colored the same and positioned the same, but each with an offset in
             * one of the 4 cardinal directions */
          
            /* God forbid the following code... */

            for _ in 0..<4 {
                let bgLabel = label.copy() as! SKLabelNode // This forcecast should be fine since the main label is also a SKLabelNode

                bgLabel.fontColor = UIColor(cgColor: CGColor(gray: 0.1, alpha: 1)) // Contrast main label
                bgLabel.zPosition = label.zPosition - 1 // Go behind it
           
                // And to scene
                target.addChild(bgLabel)

                // Add label to tracker array
                self.labelBg!.append(bgLabel)
            }
            
            // Apply offset to background labels
            let offset = label.fontSize / 5
            
            self.labelBg![0].position.x += offset
            self.labelBg![1].position.x -= offset
            self.labelBg![2].position.y += offset
            self.labelBg![3].position.y -= offset
        }
    }
   
    public func incrementScoreMultiplier(){
        self.multiplier += self.multiplierIncrement
        
        print("++'d score multiplier, new: \(self.multiplier)")
    }
    
    public func hideLabel(){
        if let label = self.label {
            label.isHidden = true
            
            if self.labelBg != nil {
                for bgLabel in self.labelBg! {
                    bgLabel.isHidden = true
                }
            }
        }
    }
   
    public func showLabel(){
        if let label = self.label {
            label.isHidden = false
            
            if self.labelBg != nil {
                for bgLabel in self.labelBg! {
                    bgLabel.isHidden = false
                }
            }
        }
    }
  
    public func keepScore() {
        // Set last score and reset current one
        self.lastScore = self.score
        
        // Evaluate high score
        if self.lastScore > self.highScore {
            self.highScore = self.lastScore
        }
    }

    @objc func addScore(){
        score += Int(CGFloat(baseScoreAward) * multiplier)

        setLabelText(to: "\(score)")
    }

    /// Start keeping score
    public func startTimer(){
        if self.awardTimer == nil {
            self.awardTimer = Timer.scheduledTimer(
                timeInterval: awardInterval,
                target: self,
                selector: #selector(addScore),
                userInfo: nil,
                repeats: true
            )
        }
    }

    /// Stop keeping score
    public func stopTimer(){
        if self.awardTimer != nil {
            self.awardTimer?.invalidate()
            self.awardTimer = nil
        }
    }
   
    /// Reset state
    public func clearState(){
        // Stop timer
        self.stopTimer()
       
        // Reset score and multiplier
        score = 0
        multiplier = 1.0

        // Set the score label accordingly
        setLabelText(to: "\(score)")
    }
}
