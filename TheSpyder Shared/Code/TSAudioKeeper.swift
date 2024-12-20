import SpriteKit

class TSAudioKeeper {
    static let shared = TSAudioKeeper()
    
    /// Play swipe sound async to avoid lagspike, use for general SFX
    public func playSoundAsync(_ sound: String, target: SKNode){
        DispatchQueue.global(qos: .background).async {
            target.run(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
        }
    }
}
