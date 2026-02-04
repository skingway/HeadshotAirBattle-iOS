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
}
