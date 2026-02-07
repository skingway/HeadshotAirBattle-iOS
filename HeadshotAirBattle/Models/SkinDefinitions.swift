import Foundation

struct AirplaneSkinDef: Identifiable {
    let id: String
    let name: String
    let description: String
    let unlockRequirement: Int
    let unlockText: String
    let color: String // Hex color
}

struct ThemeColors {
    let cellEmpty: String
    let cellAirplane: String
    let cellHit: String
    let cellMiss: String
    let cellKilled: String
    let gridLine: String
    let background: String
}

struct BoardThemeDef: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let unlockRequirement: Int
    let unlockText: String
    let colors: ThemeColors
}

enum SkinDefinitions {
    static let airplaneSkins: [AirplaneSkinDef] = [
        AirplaneSkinDef(id: "blue", name: "Classic Blue", description: "The original blue fighter",
                        unlockRequirement: 0, unlockText: "Default", color: "#3498db"),
        AirplaneSkinDef(id: "red", name: "Crimson Red", description: "Fierce red warrior",
                        unlockRequirement: 5, unlockText: "Play 5 games", color: "#e74c3c"),
        AirplaneSkinDef(id: "green", name: "Forest Green", description: "Stealth green ops",
                        unlockRequirement: 10, unlockText: "Play 10 games", color: "#2ecc71"),
        AirplaneSkinDef(id: "purple", name: "Royal Purple", description: "Majestic purple jet",
                        unlockRequirement: 15, unlockText: "Play 15 games", color: "#9b59b6"),
        AirplaneSkinDef(id: "orange", name: "Sunset Orange", description: "Blazing orange flame",
                        unlockRequirement: 20, unlockText: "Play 20 games", color: "#f39c12"),
        AirplaneSkinDef(id: "pink", name: "Hot Pink", description: "Vibrant pink power",
                        unlockRequirement: 25, unlockText: "Play 25 games", color: "#ec4899"),
        AirplaneSkinDef(id: "cyan", name: "Aqua Cyan", description: "Cool cyan skies",
                        unlockRequirement: 30, unlockText: "Play 30 games", color: "#00bcd4"),
        AirplaneSkinDef(id: "yellow", name: "Golden Yellow", description: "Brilliant gold shine",
                        unlockRequirement: 40, unlockText: "Play 40 games", color: "#f1c40f"),
        AirplaneSkinDef(id: "teal", name: "Teal Wave", description: "Ocean teal fighter",
                        unlockRequirement: 50, unlockText: "Win 10 games", color: "#1abc9c"),
        AirplaneSkinDef(id: "indigo", name: "Deep Indigo", description: "Midnight indigo sky",
                        unlockRequirement: 60, unlockText: "Win 20 games", color: "#3f51b5"),
        AirplaneSkinDef(id: "lime", name: "Neon Lime", description: "Electric lime green",
                        unlockRequirement: 70, unlockText: "Win 30 games", color: "#8bc34a"),
        AirplaneSkinDef(id: "rose", name: "Rose Gold", description: "Elegant rose gold",
                        unlockRequirement: 100, unlockText: "Win 50 games", color: "#ff6b9d"),
        // Premium skins (IAP only)
        AirplaneSkinDef(id: "diamond", name: "Diamond", description: "Brilliant diamond sparkle",
                        unlockRequirement: -1, unlockText: "Premium Skin Pack", color: "#b9f2ff"),
        AirplaneSkinDef(id: "stealth", name: "Stealth", description: "Invisible stealth fighter",
                        unlockRequirement: -1, unlockText: "Premium Skin Pack", color: "#2d2d2d"),
        AirplaneSkinDef(id: "flame", name: "Flame", description: "Blazing inferno wings",
                        unlockRequirement: -1, unlockText: "Premium Skin Pack", color: "#ff4500"),
        AirplaneSkinDef(id: "aurora", name: "Aurora", description: "Northern lights shimmer",
                        unlockRequirement: -1, unlockText: "Premium Skin Pack", color: "#00ff88"),
    ]

    static let boardThemes: [BoardThemeDef] = [
        BoardThemeDef(id: "default", name: "Ocean Blue", description: "Classic ocean theme", icon: "🌊",
                      unlockRequirement: 0, unlockText: "Default",
                      colors: ThemeColors(cellEmpty: "#1e293b", cellAirplane: "#3498db", cellHit: "#e74c3c",
                                         cellMiss: "#64748b", cellKilled: "#c0392b", gridLine: "#334155", background: "#0f172a")),
        BoardThemeDef(id: "dark", name: "Dark Mode", description: "Sleek dark theme", icon: "🌑",
                      unlockRequirement: 10, unlockText: "Win 10 games",
                      colors: ThemeColors(cellEmpty: "#111827", cellAirplane: "#6b7280", cellHit: "#ef4444",
                                         cellMiss: "#374151", cellKilled: "#991b1b", gridLine: "#1f2937", background: "#030712")),
        BoardThemeDef(id: "pink", name: "Pink Gradient", description: "Vibrant pink and purple", icon: "💗",
                      unlockRequirement: 20, unlockText: "Win 20 games",
                      colors: ThemeColors(cellEmpty: "#2d1428", cellAirplane: "#ec4899", cellHit: "#f87171",
                                         cellMiss: "#9333ea", cellKilled: "#dc2626", gridLine: "#4a1f3d", background: "#1a0a1a")),
        BoardThemeDef(id: "sunset", name: "Sunset Sky", description: "Warm sunset colors", icon: "🌅",
                      unlockRequirement: 30, unlockText: "Win 30 games",
                      colors: ThemeColors(cellEmpty: "#2d1810", cellAirplane: "#ff8f00", cellHit: "#ef5350",
                                         cellMiss: "#795548", cellKilled: "#d32f2f", gridLine: "#4a2c1a", background: "#1a0f0a")),
        BoardThemeDef(id: "forest", name: "Forest Green", description: "Natural forest tones", icon: "🌲",
                      unlockRequirement: 40, unlockText: "Win 40 games",
                      colors: ThemeColors(cellEmpty: "#1a2e1a", cellAirplane: "#4caf50", cellHit: "#ff5722",
                                         cellMiss: "#558b2f", cellKilled: "#d84315", gridLine: "#2d4a2d", background: "#0d1a0d")),
        BoardThemeDef(id: "purple", name: "Purple Dream", description: "Cosmic purple night", icon: "🌌",
                      unlockRequirement: 50, unlockText: "Win 50 games",
                      colors: ThemeColors(cellEmpty: "#190d33", cellAirplane: "#9c27b0", cellHit: "#e91e63",
                                         cellMiss: "#7e57c2", cellKilled: "#c2185b", gridLine: "#2d1b4e", background: "#0d0221")),
        BoardThemeDef(id: "arctic", name: "Arctic White", description: "Icy northern lights", icon: "❄️",
                      unlockRequirement: 100, unlockText: "Win 100 games",
                      colors: ThemeColors(cellEmpty: "#1a2a3a", cellAirplane: "#a5d8ff", cellHit: "#ff6b6b",
                                         cellMiss: "#546e7a", cellKilled: "#e63946", gridLine: "#2c3e50", background: "#0a1520")),
        BoardThemeDef(id: "golden", name: "Golden Hour", description: "Warm golden sunset", icon: "🌟",
                      unlockRequirement: 150, unlockText: "Win 150 games",
                      colors: ThemeColors(cellEmpty: "#2a1f0f", cellAirplane: "#ffd700", cellHit: "#ff6347",
                                         cellMiss: "#8b7355", cellKilled: "#dc143c", gridLine: "#4a3520", background: "#150f05")),
        BoardThemeDef(id: "nebula", name: "Nebula Space", description: "Deep space nebula", icon: "🚀",
                      unlockRequirement: 200, unlockText: "Win 200 games",
                      colors: ThemeColors(cellEmpty: "#1a0a2e", cellAirplane: "#6a0dad", cellHit: "#ff1493",
                                         cellMiss: "#483d8b", cellKilled: "#ff0066", gridLine: "#2e1a47", background: "#0a0118")),
        // Premium themes (IAP only)
        BoardThemeDef(id: "neon_city", name: "Neon City", description: "Cyberpunk neon lights", icon: "🏙️",
                      unlockRequirement: -1, unlockText: "Premium Theme Pack",
                      colors: ThemeColors(cellEmpty: "#0a0020", cellAirplane: "#ff00ff", cellHit: "#00ffff",
                                         cellMiss: "#1a0040", cellKilled: "#ff0080", gridLine: "#2a0060", background: "#050010")),
        BoardThemeDef(id: "cherry_blossom", name: "Cherry Blossom", description: "Japanese spring garden", icon: "🌸",
                      unlockRequirement: -1, unlockText: "Premium Theme Pack",
                      colors: ThemeColors(cellEmpty: "#2a1520", cellAirplane: "#ff69b4", cellHit: "#ff1744",
                                         cellMiss: "#8b4563", cellKilled: "#d50032", gridLine: "#3d2030", background: "#1a0a10")),
        BoardThemeDef(id: "midnight_gold", name: "Midnight Gold", description: "Luxurious midnight elegance", icon: "✨",
                      unlockRequirement: -1, unlockText: "Premium Theme Pack",
                      colors: ThemeColors(cellEmpty: "#1a1400", cellAirplane: "#ffd700", cellHit: "#ff4444",
                                         cellMiss: "#665500", cellKilled: "#cc0000", gridLine: "#332a00", background: "#0d0a00")),
    ]

    static func getSkin(_ id: String) -> AirplaneSkinDef? {
        return airplaneSkins.first { $0.id == id }
    }

    static func getTheme(_ id: String) -> BoardThemeDef? {
        return boardThemes.first { $0.id == id }
    }

    static func currentSkinColor() -> String {
        let skinId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.airplaneSkin) ?? "blue"
        return getSkin(skinId)?.color ?? "#3498db"
    }

    static func currentThemeColors() -> ThemeColors {
        let themeId = UserDefaults.standard.string(forKey: GameConstants.StorageKeys.boardTheme) ?? "default"
        return getTheme(themeId)?.colors ?? boardThemes[0].colors
    }
}
