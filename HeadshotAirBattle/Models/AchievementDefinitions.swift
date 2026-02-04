import Foundation

struct AchievementDef: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementDefinitions.Category
    let rarity: AchievementDefinitions.Rarity
    let checkOnGameEnd: Bool
    let checkOnStats: Bool
    let checkManually: Bool
    let rewardType: String
    let rewardTitle: String?
    let rewardValue: String?
}

enum AchievementDefinitions {
    enum Category: String, CaseIterable {
        case basic = "basic"
        case skill = "skill"
        case rare = "rare"
        case modeUnlock = "mode_unlock"

        var displayName: String {
            switch self {
            case .basic: return "Basic"
            case .skill: return "Skill"
            case .rare: return "Rare"
            case .modeUnlock: return "Mode Unlock"
            }
        }
    }

    enum Rarity: String {
        case common, rare, epic, legendary
    }

    static func rarityColor(_ rarity: Rarity) -> String {
        switch rarity {
        case .common: return "#95a5a6"
        case .rare: return "#3498db"
        case .epic: return "#9b59b6"
        case .legendary: return "#f39c12"
        }
    }

    static let all: [AchievementDef] = [
        // BASIC
        AchievementDef(id: "firstWin", name: "First Victory", description: "Win your first game", icon: "🎯",
                       category: .basic, rarity: .common, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "badge", rewardTitle: "Recruit", rewardValue: nil),
        AchievementDef(id: "tactician", name: "Tactician", description: "Complete 10 games", icon: "🎲",
                       category: .basic, rarity: .common, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "badge", rewardTitle: nil, rewardValue: nil),
        AchievementDef(id: "analyst", name: "Data Analyst", description: "View a battle report", icon: "📊",
                       category: .basic, rarity: .common, checkOnGameEnd: false, checkOnStats: false, checkManually: true,
                       rewardType: "badge", rewardTitle: nil, rewardValue: nil),

        // SKILL
        AchievementDef(id: "sharpshooter", name: "Sharpshooter", description: "Achieve ≥80% accuracy (min 10 shots)", icon: "🎯",
                       category: .skill, rarity: .rare, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "title", rewardTitle: "Precision Shooter", rewardValue: nil),
        AchievementDef(id: "lightning", name: "Lightning Strike", description: "Win within 30 moves", icon: "⚡",
                       category: .skill, rarity: .rare, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "title", rewardTitle: "Blitz Master", rewardValue: nil),
        AchievementDef(id: "streakMaster", name: "Winning Streak", description: "Achieve a 5-win streak", icon: "🔥",
                       category: .skill, rarity: .rare, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Streak Master", rewardValue: nil),
        AchievementDef(id: "perfectGame", name: "Perfectionist", description: "100% accuracy (min 10 attacks)", icon: "💯",
                       category: .skill, rarity: .epic, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "title", rewardTitle: "Perfect", rewardValue: nil),
        AchievementDef(id: "veteran", name: "Battle-Hardened Veteran", description: "Complete 100 games", icon: "🎖️",
                       category: .skill, rarity: .epic, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Veteran", rewardValue: nil),
        AchievementDef(id: "victor", name: "Victory Royale", description: "Achieve 50 total wins", icon: "👑",
                       category: .skill, rarity: .rare, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Victor", rewardValue: nil),
        AchievementDef(id: "elite", name: "Elite Player", description: "Reach 70% win rate (min 20 games)", icon: "🌟",
                       category: .skill, rarity: .epic, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Elite", rewardValue: nil),
        AchievementDef(id: "champion", name: "Champion", description: "Achieve 100 total wins", icon: "🏆",
                       category: .skill, rarity: .legendary, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Champion", rewardValue: nil),

        // RARE
        AchievementDef(id: "comeback", name: "Last Stand", description: "Win with only 1 plane remaining", icon: "🎭",
                       category: .rare, rarity: .epic, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "title", rewardTitle: "Comeback King", rewardValue: nil),
        AchievementDef(id: "prophet", name: "Prophet", description: "Hit all first 5 attacks", icon: "🔮",
                       category: .rare, rarity: .epic, checkOnGameEnd: true, checkOnStats: false, checkManually: false,
                       rewardType: "title", rewardTitle: "Oracle", rewardValue: nil),
        AchievementDef(id: "undefeated", name: "Undefeated Legend", description: "Achieve a 10-win streak", icon: "🏅",
                       category: .rare, rarity: .legendary, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "title", rewardTitle: "Undefeated", rewardValue: nil),
        AchievementDef(id: "collector", name: "Collector", description: "Unlock all skins and themes", icon: "⭐",
                       category: .rare, rarity: .legendary, checkOnGameEnd: false, checkOnStats: false, checkManually: true,
                       rewardType: "title", rewardTitle: "Collector", rewardValue: nil),
        AchievementDef(id: "completionist", name: "Completionist", description: "Unlock all other achievements", icon: "🌈",
                       category: .rare, rarity: .legendary, checkOnGameEnd: false, checkOnStats: false, checkManually: true,
                       rewardType: "title", rewardTitle: "Completionist", rewardValue: nil),

        // MODE UNLOCK
        AchievementDef(id: "mediumUnlocked", name: "AI Challenger", description: "Unlock Medium AI - Win 3 games", icon: "🤖",
                       category: .modeUnlock, rarity: .common, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "difficulty", rewardTitle: nil, rewardValue: "medium"),
        AchievementDef(id: "hardUnlocked", name: "Ultimate Challenge", description: "Unlock Hard AI - Win 10 games", icon: "🤖",
                       category: .modeUnlock, rarity: .rare, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "difficulty", rewardTitle: nil, rewardValue: "hard"),
        AchievementDef(id: "extendedUnlocked", name: "Mode Explorer", description: "Unlock Extended (15×15) - Play 10 games", icon: "🔓",
                       category: .modeUnlock, rarity: .common, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "mode", rewardTitle: nil, rewardValue: "extended"),
        AchievementDef(id: "largeUnlocked", name: "Grand Strategy", description: "Unlock Large (20×20) - Play 25 games", icon: "📐",
                       category: .modeUnlock, rarity: .rare, checkOnGameEnd: false, checkOnStats: true, checkManually: false,
                       rewardType: "mode", rewardTitle: nil, rewardValue: "large"),
    ]

    static func get(_ id: String) -> AchievementDef? {
        return all.first { $0.id == id }
    }

    static func gameEndAchievements() -> [AchievementDef] {
        return all.filter { $0.checkOnGameEnd }
    }

    static func statsAchievements() -> [AchievementDef] {
        return all.filter { $0.checkOnStats }
    }
}
