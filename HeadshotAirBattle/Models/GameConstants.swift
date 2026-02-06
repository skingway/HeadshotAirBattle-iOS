import Foundation

/// Centralized configuration for game modes, rules, and settings
enum GameConstants {

    // MARK: - Game Modes

    struct ModeConfig {
        let id: String
        let name: String
        let boardSize: Int
        let minAirplanes: Int
        let maxAirplanes: Int
        let defaultAirplanes: Int
        var isOnline: Bool = false
        // For custom mode
        var minBoardSize: Int?
        var maxBoardSize: Int?
        var defaultBoardSize: Int?
    }

    static let modes: [String: ModeConfig] = [
        "standard": ModeConfig(
            id: "standard", name: "Standard Mode",
            boardSize: 10, minAirplanes: 3, maxAirplanes: 3, defaultAirplanes: 3
        ),
        "extended": ModeConfig(
            id: "extended", name: "Extended Mode",
            boardSize: 15, minAirplanes: 6, maxAirplanes: 6, defaultAirplanes: 6
        ),
        "custom": ModeConfig(
            id: "custom", name: "Custom Mode",
            boardSize: 15, minAirplanes: 1, maxAirplanes: 10, defaultAirplanes: 3,
            minBoardSize: 10, maxBoardSize: 20, defaultBoardSize: 15
        ),
        "online": ModeConfig(
            id: "online", name: "Online PvP",
            boardSize: 10, minAirplanes: 3, maxAirplanes: 3, defaultAirplanes: 3,
            isOnline: true
        )
    ]

    // MARK: - Airplane Structure

    static let airplaneTotalCells = 10

    struct RelativePosition {
        let row: Int
        let col: Int
    }

    struct AirplaneStructure {
        static let head = RelativePosition(row: 0, col: 0)

        static let body: [RelativePosition] = [
            RelativePosition(row: 1, col: 0),
            RelativePosition(row: 2, col: 0),
            RelativePosition(row: 3, col: 0)
        ]

        static let wings: [RelativePosition] = [
            RelativePosition(row: 1, col: -2),
            RelativePosition(row: 1, col: -1),
            RelativePosition(row: 1, col: 0),  // Center overlaps with body
            RelativePosition(row: 1, col: 1),
            RelativePosition(row: 1, col: 2)
        ]

        static let tail: [RelativePosition] = [
            RelativePosition(row: 3, col: -1),
            RelativePosition(row: 3, col: 0),  // Center overlaps with body
            RelativePosition(row: 3, col: 1)
        ]
    }

    // MARK: - Directions

    enum Direction: String, CaseIterable, Codable {
        case up = "up"
        case down = "down"
        case left = "left"
        case right = "right"
    }

    struct RotationMatrix {
        let rowMult: Int
        let colMult: Int
        let swap: Bool
    }

    static let rotationMatrices: [Direction: RotationMatrix] = [
        .up: RotationMatrix(rowMult: 1, colMult: 1, swap: false),
        .down: RotationMatrix(rowMult: -1, colMult: -1, swap: false),
        .left: RotationMatrix(rowMult: -1, colMult: 1, swap: true),
        .right: RotationMatrix(rowMult: 1, colMult: -1, swap: true)
    ]

    // MARK: - Turn Timer

    enum TurnTimer {
        static let duration: TimeInterval = 5.0
        static let warningThreshold: TimeInterval = 2.0
        static let tickInterval: TimeInterval = 0.1
    }

    // MARK: - AI Difficulty

    enum AIDifficulty: String, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"

        var name: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }

        var description: String {
            switch self {
            case .easy: return "Random attacks"
            case .medium: return "Random + smart follow-up"
            case .hard: return "Intelligent head targeting"
            }
        }
    }

    // MARK: - Game Phases

    enum GamePhase: String {
        case menu = "menu"
        case modeSelect = "mode_select"
        case difficultySelect = "difficulty_select"
        case deployment = "deployment"
        case battle = "battle"
        case gameOver = "game_over"
        case matchmaking = "matchmaking"
        case waiting = "waiting"
    }

    // MARK: - Cell States

    enum CellState: String {
        case empty = "empty"
        case airplane = "airplane"
        case hit = "hit"
        case miss = "miss"
        case killed = "killed"
    }

    // MARK: - Attack Results

    enum AttackResult: String, Codable {
        case miss = "miss"
        case hit = "hit"
        case kill = "kill"
        case alreadyAttacked = "already_attacked"
        case invalid = "invalid"
    }

    // MARK: - Player Types

    enum PlayerType: String {
        case human = "human"
        case ai = "ai"
        case online = "online"
    }

    // MARK: - Game Types

    enum GameType: String, Codable {
        case ai = "ai"
        case online = "online"
    }

    // MARK: - Online Game Status

    enum OnlineGameStatus: String, Codable {
        case waiting = "waiting"
        case deploying = "deploying"
        case battle = "battle"
        case finished = "finished"
    }

    // MARK: - Audio Settings

    enum Audio {
        static let bgmVolume: Float = 0.3
        static let sfxVolume: Float = 0.5
        static let enabledByDefault = true
    }

    // MARK: - Network Settings

    enum Network {
        static let disconnectGracePeriod: TimeInterval = 30.0
        static let reconnectAttempts = 3
        static let reconnectDelay: TimeInterval = 2.0
        static let matchmakingTimeout: TimeInterval = 60.0
    }

    // MARK: - Validation Rules

    enum Validation {
        static let minNicknameLength = 1
        static let maxNicknameLength = 20
        static let nicknameChangeCooldown: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        // 允许字母、数字、下划线和中文字符
        static let nicknamePattern = "^[a-zA-Z0-9_\u{4e00}-\u{9fa5}]+$"
    }

    // MARK: - Storage Keys (UserDefaults)

    enum StorageKeys {
        static let currentUser = "airplanebattle_current_user"
        static let audioEnabled = "airplanebattle_audio_enabled"
        static let bgmVolume = "airplanebattle_bgm_volume"
        static let sfxVolume = "airplanebattle_sfx_volume"
        static let savedGame = "airplanebattle_saved_game"
        static let offlineUserProfile = "offline_user_profile"
        static let offlineStatistics = "offline_statistics"
        static let offlineGameHistory = "offline_game_history"
        static let achievementsData = "achievements_data"
        static let airplaneSkin = "@airplane_skin"
        static let boardTheme = "@board_theme"
    }

    // MARK: - Animation Durations

    enum Animations {
        static let fadeDuration: TimeInterval = 0.3
        static let slideDuration: TimeInterval = 0.4
        static let attackDuration: TimeInterval = 0.5
        static let explosionDuration: TimeInterval = 0.8
    }

    // MARK: - Grid Display

    enum GridDisplay {
        static let minCellSize: CGFloat = 20
        static let maxCellSize: CGFloat = 50
        static let cellGap: CGFloat = 2
        static let labelSize: CGFloat = 30
    }

    // MARK: - Room Code

    static let roomCodeCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    static let roomCodeLength = 6

    // MARK: - Utility Functions

    static func getModeConfig(_ modeId: String) -> ModeConfig {
        return modes[modeId] ?? modes["standard"]!
    }

    static func isValidCustomBoardSize(_ size: Int) -> Bool {
        guard let custom = modes["custom"] else { return false }
        return size >= (custom.minBoardSize ?? 10) && size <= (custom.maxBoardSize ?? 20)
    }

    static func validateAirplaneCountForBoardSize(airplaneCount: Int, boardSize: Int) -> (valid: Bool, reason: String, recommendation: String) {
        let totalCells = boardSize * boardSize
        let airplaneCells = airplaneCount * airplaneTotalCells
        let occupancyRate = Double(airplaneCells) / Double(totalCells)
        let maxRecommendedOccupancy = 0.40

        if occupancyRate > maxRecommendedOccupancy {
            let recommendedMax = Int(floor(Double(totalCells) * maxRecommendedOccupancy / Double(airplaneTotalCells)))
            return (
                valid: false,
                reason: "\(airplaneCount) airplanes would occupy \(String(format: "%.1f", occupancyRate * 100))% of the \(boardSize)×\(boardSize) board.",
                recommendation: "For a \(boardSize)×\(boardSize) board, we recommend at most \(recommendedMax) airplanes."
            )
        }

        return (valid: true, reason: "", recommendation: "")
    }
}
