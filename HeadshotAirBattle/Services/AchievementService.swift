import Foundation

/// Manages achievement tracking, unlocking, and persistence
class AchievementService {
    static let shared = AchievementService()

    private var unlockedIds: Set<String> = []
    private var listeners: [(String) -> Void] = []

    private init() {
        loadFromStorage()
    }

    // MARK: - Query

    func isUnlocked(_ achievementId: String) -> Bool {
        return unlockedIds.contains(achievementId)
    }

    func getUnlockedIds() -> [String] {
        return Array(unlockedIds)
    }

    func getProgress() -> (total: Int, unlocked: Int, percentage: Double) {
        let total = AchievementDefinitions.all.count
        let unlocked = unlockedIds.count
        let percentage = total > 0 ? Double(unlocked) / Double(total) * 100 : 0
        return (total, unlocked, percentage)
    }

    // MARK: - Unlock

    func unlockAchievement(_ achievementId: String) {
        guard !unlockedIds.contains(achievementId) else { return }
        guard AchievementDefinitions.get(achievementId) != nil else { return }

        unlockedIds.insert(achievementId)
        saveToStorage()

        // Notify listeners
        for listener in listeners {
            listener(achievementId)
        }
    }

    // MARK: - Check Game End Achievements

    func checkGameEndAchievements(gameResult: GameResult, userStats: Statistics) {
        for achievement in AchievementDefinitions.gameEndAchievements() {
            if isUnlocked(achievement.id) { continue }

            var shouldUnlock = false

            switch achievement.id {
            case "firstWin":
                shouldUnlock = userStats.wins >= 1
            case "sharpshooter":
                let total = gameResult.playerStats.hits + gameResult.playerStats.misses
                if total >= 10 {
                    let accuracy = Double(gameResult.playerStats.hits) / Double(total) * 100
                    shouldUnlock = accuracy >= 80
                }
            case "lightning":
                shouldUnlock = gameResult.winner != "AI" && gameResult.totalTurns <= 30
            case "perfectGame":
                let total = gameResult.playerStats.hits + gameResult.playerStats.misses
                shouldUnlock = total >= 10 && gameResult.playerStats.misses == 0
            case "comeback":
                shouldUnlock = gameResult.comebackWin
            case "prophet":
                shouldUnlock = gameResult.first5AllHit
            default:
                break
            }

            if shouldUnlock {
                unlockAchievement(achievement.id)
            }
        }
    }

    // MARK: - Check Stats Achievements

    func checkStatsAchievements(userStats: Statistics) {
        for achievement in AchievementDefinitions.statsAchievements() {
            if isUnlocked(achievement.id) { continue }

            var shouldUnlock = false

            switch achievement.id {
            case "tactician":
                shouldUnlock = userStats.totalGames >= 10
            case "streakMaster":
                shouldUnlock = (userStats.currentStreak ?? 0) >= 5
            case "veteran":
                shouldUnlock = userStats.totalGames >= 100
            case "victor":
                shouldUnlock = userStats.wins >= 50
            case "elite":
                shouldUnlock = userStats.totalGames >= 20 && userStats.winRate >= 70
            case "champion":
                shouldUnlock = userStats.wins >= 100
            case "undefeated":
                shouldUnlock = (userStats.currentStreak ?? 0) >= 10
            case "mediumUnlocked":
                shouldUnlock = userStats.wins >= 3
            case "hardUnlocked":
                shouldUnlock = userStats.wins >= 10
            case "extendedUnlocked":
                shouldUnlock = userStats.totalGames >= 10
            case "largeUnlocked":
                shouldUnlock = userStats.totalGames >= 25
            default:
                break
            }

            if shouldUnlock {
                unlockAchievement(achievement.id)
            }
        }
    }

    // MARK: - Difficulty/Mode Unlock Checks

    func isDifficultyUnlocked(_ difficulty: GameConstants.AIDifficulty) -> Bool {
        switch difficulty {
        case .easy: return true
        case .medium: return isUnlocked("mediumUnlocked")
        case .hard: return isUnlocked("hardUnlocked")
        }
    }

    func isModeUnlocked(boardSize: Int) -> Bool {
        switch boardSize {
        case 10: return true
        case 15: return isUnlocked("extendedUnlocked")
        case 20: return isUnlocked("largeUnlocked")
        default: return true
        }
    }

    // MARK: - Manual Unlocks

    func manuallyUnlock(_ achievementId: String) {
        unlockAchievement(achievementId)
    }

    func checkCollectorAchievement(allSkinsUnlocked: Bool) {
        if allSkinsUnlocked {
            unlockAchievement("collector")
        }
    }

    func checkCompletionistAchievement() {
        let allOtherIds = AchievementDefinitions.all
            .filter { $0.id != "completionist" }
            .map { $0.id }
        let allUnlocked = allOtherIds.allSatisfy { unlockedIds.contains($0) }
        if allUnlocked {
            unlockAchievement("completionist")
        }
    }

    // MARK: - Listeners

    func addListener(_ listener: @escaping (String) -> Void) {
        listeners.append(listener)
    }

    // MARK: - Persistence

    private func saveToStorage() {
        let data = AchievementsData(
            unlocked: Array(unlockedIds),
            lastUpdated: Date().millisecondsSince1970
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: GameConstants.StorageKeys.achievementsData)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.achievementsData),
              let saved = try? JSONDecoder().decode(AchievementsData.self, from: data) else {
            return
        }
        unlockedIds = Set(saved.unlocked)
    }

    func reset() {
        unlockedIds.removeAll()
        saveToStorage()
    }
}
