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
}
