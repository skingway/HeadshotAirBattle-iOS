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

    func isSkinUnlocked(_ skin: AirplaneSkinDef, totalGames: Int, wins: Int) -> Bool {
        return SkinService.shared.isSkinUnlocked(skin, totalGames: totalGames, wins: wins)
    }

    func isThemeUnlocked(_ theme: BoardThemeDef, totalWins: Int) -> Bool {
        return SkinService.shared.isThemeUnlocked(theme, wins: totalWins)
    }

    func skinUnlockProgress(_ skin: AirplaneSkinDef, totalGames: Int, wins: Int) -> String {
        if isSkinUnlocked(skin, totalGames: totalGames, wins: wins) {
            return "Unlocked"
        }
        // Premium skins require IAP
        if skin.unlockRequirement < 0 {
            return skin.unlockText
        }
        if skin.unlockType == "wins" {
            let remaining = skin.unlockRequirement - wins
            return "Need \(remaining) more win\(remaining == 1 ? "" : "s") or Premium Skin Pack"
        }
        let remaining = skin.unlockRequirement - totalGames
        return "Need \(remaining) more game\(remaining == 1 ? "" : "s") or Premium Skin Pack"
    }

    func themeUnlockProgress(_ theme: BoardThemeDef, totalWins: Int) -> String {
        if isThemeUnlocked(theme, totalWins: totalWins) {
            return "Unlocked"
        }
        // Premium themes require IAP
        if theme.unlockRequirement < 0 {
            return theme.unlockText
        }
        let remaining = theme.unlockRequirement - totalWins
        return "Need \(remaining) more win\(remaining == 1 ? "" : "s") or Premium Theme Pack"
    }
}
