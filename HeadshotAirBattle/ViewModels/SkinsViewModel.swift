import SwiftUI

@MainActor
class SkinsViewModel: ObservableObject {
    @Published var currentSkinId: String = "blue"
    @Published var currentThemeId: String = "default"

    func load() {
        currentSkinId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.airplaneSkin) ?? "blue"
        currentThemeId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.boardTheme) ?? "default"
    }

    func selectSkin(_ skinId: String) {
        currentSkinId = skinId
        UserDefaults.standard.set(skinId, forKey: GameConstants.StorageKeys.airplaneSkin)
    }

    func selectTheme(_ themeId: String) {
        currentThemeId = themeId
        UserDefaults.standard.set(themeId, forKey: GameConstants.StorageKeys.boardTheme)
    }

    func isSkinUnlocked(_ skin: AirplaneSkinDef, totalGames: Int) -> Bool {
        return totalGames >= skin.unlockRequirement
    }

    func isThemeUnlocked(_ theme: BoardThemeDef, totalWins: Int) -> Bool {
        return totalWins >= theme.unlockRequirement
    }

    func skinUnlockProgress(_ skin: AirplaneSkinDef, totalGames: Int) -> String {
        if totalGames >= skin.unlockRequirement {
            return "Unlocked"
        }
        let remaining = skin.unlockRequirement - totalGames
        return "Need \(remaining) more game\(remaining == 1 ? "" : "s")"
    }

    func themeUnlockProgress(_ theme: BoardThemeDef, totalWins: Int) -> String {
        if totalWins >= theme.unlockRequirement {
            return "Unlocked"
        }
        let remaining = theme.unlockRequirement - totalWins
        return "Need \(remaining) more win\(remaining == 1 ? "" : "s")"
    }
}
