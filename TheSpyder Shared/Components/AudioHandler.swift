import SpriteKit

class AudioHandler {
    static let shared = AudioHandler()
    
    /// Play swipe sound async to avoid lagspike, use for general SFX
    public func playSoundAsync(_ sound: String, target: SKNode){
        DispatchQueue.global(qos: .background).async {
            target.run(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
        }
    }
}
