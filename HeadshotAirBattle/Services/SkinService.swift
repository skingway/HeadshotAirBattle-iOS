import Foundation

/// Manages skin and theme preferences
class SkinService {
    static let shared = SkinService()

    private(set) var currentSkinId: String = "blue"
    private(set) var currentThemeId: String = "default"

    private init() {
        load()
    }

    func load() {
        currentSkinId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.airplaneSkin) ?? "blue"
        currentThemeId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.boardTheme) ?? "default"
    }

    func getCurrentSkinColor() -> String {
        return SkinDefinitions.getSkin(currentSkinId)?.color ?? "#3498db"
    }

    func getCurrentThemeColors() -> ThemeColors {
        return SkinDefinitions.getTheme(currentThemeId)?.colors ?? SkinDefinitions.boardThemes[0].colors
    }

    func setAirplaneSkin(_ skinId: String) {
        guard SkinDefinitions.getSkin(skinId) != nil else { return }
        currentSkinId = skinId
        UserDefaults.standard.set(skinId, forKey: GameConstants.StorageKeys.airplaneSkin)
    }

    func setBoardTheme(_ themeId: String) {
        guard SkinDefinitions.getTheme(themeId) != nil else { return }
        currentThemeId = themeId
        UserDefaults.standard.set(themeId, forKey: GameConstants.StorageKeys.boardTheme)
    }

    func reset() {
        setAirplaneSkin("blue")
        setBoardTheme("default")
    }

    /// Check if a skin is unlocked (by games played or IAP purchase)
    @MainActor
    func isSkinUnlocked(_ skin: AirplaneSkinDef, totalGames: Int) -> Bool {
        // Purchased Premium Skin Pack → unlock ALL skins
        if IAPService.shared.isPurchased(.premiumSkinPack) {
            return true
        }
        // Premium skins (unlockRequirement == -1): require IAP only
        if skin.unlockRequirement < 0 {
            return false
        }
        // Regular skins: unlock by games played
        return totalGames >= skin.unlockRequirement
    }

    /// Check if a theme is unlocked (by wins or IAP purchase)
    @MainActor
    func isThemeUnlocked(_ theme: BoardThemeDef, wins: Int) -> Bool {
        // Purchased Premium Theme Pack → unlock ALL themes
        if IAPService.shared.isPurchased(.premiumThemePack) {
            return true
        }
        // Premium themes (unlockRequirement == -1): require IAP only
        if theme.unlockRequirement < 0 {
            return false
        }
        // Regular themes: unlock by wins
        return wins >= theme.unlockRequirement
    }
}
