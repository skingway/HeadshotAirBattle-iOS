import SwiftUI

struct AppColors {
    // === Background Colors ===
    static let bgPrimary = Color(red: 10/255, green: 14/255, blue: 26/255)        // #0a0e1a
    static let bgSecondary = Color(red: 13/255, green: 21/255, blue: 38/255)       // #0d1526
    static let bgCard = Color(red: 0, green: 30/255, blue: 60/255).opacity(0.6)
    static let bgCardHighlight = Color(red: 0, green: 40/255, blue: 80/255).opacity(0.7)

    // === Primary Accent - Cyan Glow ===
    static let accent = Color(red: 0, green: 212/255, blue: 255/255)               // #00d4ff
    static let accentDim = Color(red: 0, green: 212/255, blue: 255/255).opacity(0.15)
    static let accentBorder = Color(red: 0, green: 212/255, blue: 255/255).opacity(0.3)
    static let accentGlow = Color(red: 0, green: 212/255, blue: 255/255).opacity(0.4)
    static let accentSoft = Color(red: 0, green: 212/255, blue: 255/255).opacity(0.08)

    // === Gold ===
    static let gold = Color(red: 255/255, green: 215/255, blue: 0)                 // #ffd700
    static let goldDark = Color(red: 255/255, green: 140/255, blue: 0)              // #ff8c00

    // === Functional Colors ===
    static let danger = Color(red: 255/255, green: 68/255, blue: 68/255)            // #ff4444
    static let dangerDim = Color(red: 255/255, green: 68/255, blue: 68/255).opacity(0.15)
    static let dangerBorder = Color(red: 255/255, green: 68/255, blue: 68/255).opacity(0.3)
    static let success = Color(red: 0, green: 255/255, blue: 136/255)               // #00ff88
    static let successDim = Color(red: 0, green: 255/255, blue: 136/255).opacity(0.15)
    static let successBorder = Color(red: 0, green: 255/255, blue: 136/255).opacity(0.3)
    static let warning = Color(red: 255/255, green: 140/255, blue: 0)               // #ff8c00

    // === Text Colors ===
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.5)
    static let textDark = Color.white.opacity(0.3)

    // === Border / Divider ===
    static let border = Color.white.opacity(0.1)
    static let borderLight = Color.white.opacity(0.06)
    static let divider = Color.white.opacity(0.05)

    // === Gradients ===
    static let primaryGradient = LinearGradient(
        colors: [accent, Color(red: 0, green: 136/255, blue: 204/255)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [gold, goldDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, bgSecondary, bgPrimary],
        startPoint: .top, endPoint: .bottom
    )
}
