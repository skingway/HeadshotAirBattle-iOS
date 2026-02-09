import Foundation

// MARK: - User Profile

struct UserProfile: Codable {
    var userId: String
    var nickname: String
    var nicknameChangedAt: Double?
    var createdAt: Double
    var selectedBackground: String?
    var totalGames: Int
    var wins: Int
    var losses: Int
    var winRate: Double
    var onlineGames: Int?
    var authProvider: String  // "anonymous", "apple"
    var appleDisplayName: String?
    var appleEmail: String?
    var linkedAt: Double?

    init(userId: String, nickname: String) {
        self.userId = userId
        self.nickname = nickname
        self.nicknameChangedAt = nil
        self.createdAt = Date().timeIntervalSince1970 * 1000
        self.selectedBackground = nil
        self.totalGames = 0
        self.wins = 0
        self.losses = 0
        self.winRate = 0
        self.onlineGames = nil
        self.authProvider = "anonymous"
        self.appleDisplayName = nil
        self.appleEmail = nil
        self.linkedAt = nil
    }
}

// MARK: - Game History Entry

struct GameHistoryEntry: Codable, Identifiable {
    var id: String?
    var userId: String
    var gameType: String // "ai" or "online"
    var opponent: String
    var winner: String
    var boardSize: Int
    var airplaneCount: Int
    var totalTurns: Int
    var completedAt: Double
    var startedAt: Double?
    var players: [String]
    var playerStats: GameStats?
    var aiStats: GameStats?
    var playerBoardData: BoardData?
    var aiBoardData: BoardData?
}

struct GameStats: Codable {
    var hits: Int
    var misses: Int
    var kills: Int

    init(hits: Int = 0, misses: Int = 0, kills: Int = 0) {
        self.hits = hits
        self.misses = misses
        self.kills = kills
    }
}

struct BoardData: Codable {
    var size: Int
    var airplaneCount: Int
    var airplanes: [AirplaneData]
    var attackHistory: [AttackRecord]
    var attackedCells: [String]
}

struct AirplaneData: Codable {
    var id: Int
    var headRow: Int
    var headCol: Int
    var direction: String
    var hits: [String]?
    var isDestroyed: Bool?
}

struct AttackRecord: Codable {
    var row: Int
    var col: Int
    var coordinate: String?
    var result: String
    var airplaneId: Int?
    var cellType: String?
    var wasHead: Bool?
    var timestamp: Double?
}

// MARK: - Matchmaking Queue Entry

struct QueueEntry: Codable {
    var userId: String
    var nickname: String
    var totalGames: Int
    var winRate: Double
    var preferredMode: String
    var joinedAt: Double
    var status: String // "waiting" or "matched"
    var matchId: String?
}

// MARK: - Online Game State (Realtime Database)

struct OnlineGameState: Codable {
    var gameId: String
    var gameType: String // "quickMatch" or "privateRoom"
    var roomCode: String?
    var status: String // "waiting", "deploying", "battle", "finished"
    var mode: String
    var boardSize: Int
    var airplaneCount: Int
    var createdAt: Double
    var player1: GamePlayer?
    var player2: GamePlayer?
    var currentTurn: String?
    var turnStartedAt: Double?
    var winner: String?
    var completedAt: Double?
    var battleStartedAt: Double?
}

struct GamePlayer: Codable {
    var id: String
    var nickname: String
    var ready: Bool
    var connected: Bool
    var board: PlayerBoard?
    var attacks: [String: OnlineAttackRecord]?
    var stats: GameStats

    init(id: String, nickname: String) {
        self.id = id
        self.nickname = nickname
        self.ready = false
        self.connected = true
        self.board = nil
        self.attacks = nil
        self.stats = GameStats()
    }
}

struct PlayerBoard: Codable {
    var airplanes: [AirplaneData]
}

struct OnlineAttackRecord: Codable {
    var row: Int
    var col: Int
    var result: String
    var timestamp: Double
}

// MARK: - Room Code

struct RoomCodeEntry: Codable {
    var gameId: String
    var hostId: String
    var createdAt: Double
    var expiresAt: Double
}

// MARK: - Statistics

struct Statistics: Codable {
    var totalGames: Int
    var wins: Int
    var losses: Int
    var winRate: Double
    var onlineGames: Int?
    var currentStreak: Int?

    init(totalGames: Int = 0, wins: Int = 0, losses: Int = 0, winRate: Double = 0, onlineGames: Int? = nil, currentStreak: Int? = 0) {
        self.totalGames = totalGames
        self.wins = wins
        self.losses = losses
        self.winRate = winRate
        self.onlineGames = onlineGames
        self.currentStreak = currentStreak
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { userId }
    var userId: String
    var nickname: String
    var totalGames: Int
    var wins: Int
    var winRate: Double
    var rank: Int?
}
