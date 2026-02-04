import Foundation

/// Represents the current phase/state of a game session
enum GamePhaseState: Equatable {
    case menu
    case modeSelect
    case difficultySelect(mode: String)
    case deployment(mode: String, difficulty: String, boardSize: Int, airplaneCount: Int)
    case countdown
    case battle
    case gameOver(winner: String)
}

/// Represents an ongoing game's result data
struct GameResult {
    var winner: String // "player" or "AI" or userId
    var totalTurns: Int
    var playerStats: GameStats
    var aiStats: GameStats?
    var comebackWin: Bool
    var first5AllHit: Bool
    var boardSize: Int
    var airplaneCount: Int
    var gameType: GameConstants.GameType
    var opponent: String
}
