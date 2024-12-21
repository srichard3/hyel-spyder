enum TTGameState: Equatable{
    case title
    case inGame
    case gameOver
    case none
}

struct TSGameInfo {
    public func getLastScore() -> Int {
        return TSScoreKeeper.shared.getLastScore()
    }
    
    public func getHighScore() -> Int {
        return TSScoreKeeper.shared.getHighScore()
    }
    
    public func getCurrentScore() -> Int {
        return TSScoreKeeper.shared.getCurrentScore()
    }
}
