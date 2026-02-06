import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var phase: GamePhase = .deployment
    @Published var playerBoard: BoardManager?
    @Published var opponentBoard: BoardManager?
    @Published var isPlayerTurn = true
    @Published var lastAttackResult: GameConstants.AttackResult?
    @Published var didPlayerWin = false
    @Published var totalTurns = 0
    @Published var playerStats: GameStats?
    @Published var aiStats: GameStats?
    @Published var gameLog: [String] = []
    @Published var turnTimeRemaining: TimeInterval = 5.0
    @Published var deployedAirplanes: [Airplane] = []

    enum GamePhase {
        case deployment, countdown, battle, gameOver
    }

    // Config
    private var difficulty: GameConstants.AIDifficulty = .easy
    private var mode: String = "standard"
    private var boardSize: Int = 10
    private var airplaneCount: Int = 3
    private var ai: AIStrategy?
    private var turnTimer: Timer?
    private var userId: String = ""

    var playerAccuracy: Double {
        guard let stats = playerStats else { return 0 }
        let total = stats.hits + stats.misses
        return total > 0 ? Double(stats.hits) / Double(total) * 100 : 0
    }

    // MARK: - Setup

    func setup(difficulty: String, mode: String, boardSize: Int, airplaneCount: Int, userId: String = "") {
        self.userId = userId
        self.difficulty = GameConstants.AIDifficulty(rawValue: difficulty) ?? .easy
        self.mode = mode
        self.boardSize = boardSize
        self.airplaneCount = airplaneCount

        // Create boards
        playerBoard = BoardManager(size: boardSize, airplaneCount: airplaneCount)
        opponentBoard = BoardManager(size: boardSize, airplaneCount: airplaneCount)

        // Place AI airplanes randomly
        _ = opponentBoard?.placeAirplanesRandomly()

        // Create AI
        ai = AIStrategy.create(difficulty: self.difficulty, boardSize: boardSize)

        // Reset state
        phase = .deployment
        isPlayerTurn = true
        didPlayerWin = false
        totalTurns = 0
        playerStats = nil
        aiStats = nil
        gameLog.removeAll()
        deployedAirplanes.removeAll()
        turnTimeRemaining = GameConstants.TurnTimer.duration
    }

    // MARK: - Deployment

    func deployAirplanesRandomly() {
        guard let board = playerBoard else { return }
        if board.placeAirplanesRandomly() {
            deployedAirplanes = board.airplanes
        }
    }

    func addAirplane(headRow: Int, headCol: Int, direction: GameConstants.Direction) -> Bool {
        guard let board = playerBoard else { return false }
        let id = board.airplanes.count
        let airplane = Airplane(headRow: headRow, headCol: headCol, direction: direction, id: id)
        let result = board.addAirplane(airplane)
        if result.success {
            deployedAirplanes = board.airplanes
        }
        return result.success
    }

    func removeAirplane(id: Int) {
        guard let board = playerBoard else { return }
        _ = board.removeAirplane(id: id)
        deployedAirplanes = board.airplanes
    }

    func clearDeployment() {
        playerBoard?.clearAirplanes()
        deployedAirplanes.removeAll()
    }

    func isDeploymentComplete() -> Bool {
        return playerBoard?.isDeploymentComplete() ?? false
    }

    func confirmDeployment() {
        guard isDeploymentComplete() else { return }
        phase = .countdown
    }

    // MARK: - Battle

    func startBattle() {
        phase = .battle
        isPlayerTurn = true
        startTurnTimer()
    }

    func playerAttack(row: Int, col: Int) {
        guard phase == .battle, isPlayerTurn else { return }
        guard let board = opponentBoard else { return }

        // Check already attacked
        if board.isCellAttacked(row: row, col: col) { return }

        stopTurnTimer()

        let result = board.processAttack(row: row, col: col)
        lastAttackResult = result.result
        totalTurns += 1

        // Log
        let coord = CoordinateSystem.positionToCoordinate(row: row, col: col)
        gameLog.append("You attacked \(coord): \(result.result.rawValue.uppercased())")

        // Play sound
        AudioService.shared.playSFX(for: result.result)

        // Check win
        if board.areAllAirplanesDestroyed() {
            endGame(playerWon: true)
            return
        }

        // Switch to AI turn
        isPlayerTurn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.aiTurn()
        }
    }

    private func aiTurn() {
        guard phase == .battle, !isPlayerTurn else { return }
        guard let ai = ai, let playerBoard = playerBoard else { return }

        guard let target = ai.getNextAttack(opponentBoard: playerBoard) else {
            endGame(playerWon: true)
            return
        }

        let result = playerBoard.processAttack(row: target.row, col: target.col)
        totalTurns += 1

        // Update AI state
        ai.processAttackResult(attackPos: target, result: result)

        // Log
        let coord = CoordinateSystem.positionToCoordinate(row: target.row, col: target.col)
        gameLog.append("AI attacked \(coord): \(result.result.rawValue.uppercased())")

        // Play sound
        AudioService.shared.playSFX(for: result.result)

        // 强制触发界面刷新 - playerBoard 内部状态变化后需要通知 SwiftUI
        objectWillChange.send()

        // Check loss
        if playerBoard.areAllAirplanesDestroyed() {
            endGame(playerWon: false)
            return
        }

        // Switch back to player
        isPlayerTurn = true
        startTurnTimer()
    }

    // MARK: - Turn Timer

    private func startTurnTimer() {
        turnTimeRemaining = GameConstants.TurnTimer.duration
        turnTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.TurnTimer.tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.turnTimeRemaining -= GameConstants.TurnTimer.tickInterval
                if self.turnTimeRemaining <= 0 {
                    self.handleTurnTimeout()
                }
            }
        }
    }

    private func stopTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
    }

    private func handleTurnTimeout() {
        stopTurnTimer()
        guard phase == .battle, isPlayerTurn else { return }

        // Auto-attack random cell
        guard let board = opponentBoard else { return }
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                if !board.isCellAttacked(row: row, col: col) {
                    playerAttack(row: row, col: col)
                    return
                }
            }
        }
    }

    // MARK: - Game End

    private func endGame(playerWon: Bool) {
        stopTurnTimer()
        phase = .gameOver
        didPlayerWin = playerWon

        playerStats = opponentBoard?.getStatistics() // Player's attacks on opponent board
        aiStats = playerBoard?.getStatistics()       // AI's attacks on player board

        // Save stats
        Task {
            await saveGameResults()
        }
    }

    private func saveGameResults() async {
        guard !userId.isEmpty else {
            print("[GameViewModel] Cannot save: userId is empty")
            return
        }

        // 更新统计数据
        let updatedStats = await StatisticsService.shared.updateStatistics(
            userId: userId,
            isWinner: didPlayerWin,
            isOnlineGame: false
        )

        // 检查成就解锁
        let gameResult = GameResult(
            winner: didPlayerWin ? userId : "AI",
            totalTurns: totalTurns,
            playerStats: playerStats ?? GameStats(),
            aiStats: aiStats,
            comebackWin: checkComebackWin(),
            first5AllHit: checkFirst5AllHit(),
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            gameType: .ai,
            opponent: "AI (\(difficulty.name))"
        )
        AchievementService.shared.checkGameEndAchievements(gameResult: gameResult, userStats: updatedStats)
        AchievementService.shared.checkStatsAchievements(userStats: updatedStats)

        // 保存游戏历史（包含棋盘数据用于战报回看）
        let historyEntry = GameHistoryEntry(
            id: UUID().uuidString,
            userId: userId,
            gameType: "ai",
            opponent: "AI (\(difficulty.name))",
            winner: didPlayerWin ? userId : "AI",
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            totalTurns: totalTurns,
            completedAt: Date().millisecondsSince1970,
            players: [userId, "AI"],
            playerStats: playerStats,
            aiStats: aiStats,
            playerBoardData: playerBoard?.toData(),
            aiBoardData: opponentBoard?.toData()
        )

        await StatisticsService.shared.saveGameHistory(
            userId: userId,
            gameData: historyEntry
        )

        print("[GameViewModel] Game results saved for user: \(userId)")
    }

    // 检查是否是逆转胜利（对方已摧毁2架飞机时获胜）
    private func checkComebackWin() -> Bool {
        guard didPlayerWin else { return false }
        let destroyedCount = playerBoard?.airplanes.filter { $0.isDestroyed }.count ?? 0
        return destroyedCount >= 2
    }

    // 检查前5次攻击是否全部命中
    private func checkFirst5AllHit() -> Bool {
        guard let board = opponentBoard else { return false }
        let first5 = board.attackHistory.prefix(5)
        guard first5.count >= 5 else { return false }
        return first5.allSatisfy { $0.result != GameConstants.AttackResult.miss.rawValue }
    }
}

// MARK: - DeploymentViewModel (shared logic)

@MainActor
class DeploymentViewModel: ObservableObject {
    @Published var selectedDirection: GameConstants.Direction = .up
    @Published var airplanes: [Airplane] = []

    weak var gameViewModel: GameViewModel?

    func rotateDirection() {
        let allDirs = GameConstants.Direction.allCases
        if let index = allDirs.firstIndex(of: selectedDirection) {
            selectedDirection = allDirs[(index + 1) % allDirs.count]
        }
    }

    func placeAirplane(headRow: Int, headCol: Int) -> Bool {
        return gameViewModel?.addAirplane(headRow: headRow, headCol: headCol, direction: selectedDirection) ?? false
    }

    func randomPlacement() {
        gameViewModel?.deployAirplanesRandomly()
        airplanes = gameViewModel?.deployedAirplanes ?? []
    }

    func clearAll() {
        gameViewModel?.clearDeployment()
        airplanes.removeAll()
    }

    func confirmDeployment() {
        gameViewModel?.confirmDeployment()
    }

    var isComplete: Bool {
        return gameViewModel?.isDeploymentComplete() ?? false
    }
}
