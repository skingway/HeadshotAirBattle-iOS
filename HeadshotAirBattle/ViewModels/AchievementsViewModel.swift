import SwiftUI

@MainActor
class AchievementsViewModel: ObservableObject {
    @Published var unlockedIds: Set<String> = []
    @Published var totalCount = 0
    @Published var unlockedCount = 0

    func load() {
        let allAchievements = AchievementDefinitions.all
        totalCount = allAchievements.count

        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: GameConstants.StorageKeys.achievementsData),
           let saved = try? JSONDecoder().decode(AchievementsData.self, from: data) {
            unlockedIds = Set(saved.unlocked)
        }

        unlockedCount = unlockedIds.count
    }

    func isUnlocked(_ achievementId: String) -> Bool {
        return unlockedIds.contains(achievementId)
    }

    func achievements(for category: AchievementDefinitions.Category) -> [AchievementDef] {
        return AchievementDefinitions.all.filter { $0.category == category }
    }
}

struct AchievementsData: Codable {
    var unlocked: [String]
    var lastUpdated: Double?
}
