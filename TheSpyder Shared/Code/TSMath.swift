import SpriteKit

public class TSMath{
    /// Simple linear interpolation
    public static func lerp(_ start: CGFloat, _ end: CGFloat, _ t: CGFloat) -> CGFloat{
        return (1 - t) * start + t * end
    }
}
