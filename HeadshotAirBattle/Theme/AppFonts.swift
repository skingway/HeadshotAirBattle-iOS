import SwiftUI

struct AppFonts {
    // === Orbitron - Titles/Numbers/Buttons ===
    static func orbitron(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .black:     return .custom("Orbitron-Black", size: size)
        case .heavy:     return .custom("Orbitron-ExtraBold", size: size)
        case .bold:      return .custom("Orbitron-Bold", size: size)
        case .semibold:  return .custom("Orbitron-SemiBold", size: size)
        case .medium:    return .custom("Orbitron-Medium", size: size)
        default:         return .custom("Orbitron-Regular", size: size)
        }
    }

    // === Rajdhani - Body/Descriptions/Labels ===
    static func rajdhani(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:      return .custom("Rajdhani-Bold", size: size)
        case .semibold:  return .custom("Rajdhani-SemiBold", size: size)
        case .medium:    return .custom("Rajdhani-Medium", size: size)
        default:         return .custom("Rajdhani-Regular", size: size)
        }
    }

    // === Preset Styles ===
    static let gameLogo     = orbitron(26, weight: .bold)
    static let pageTitle    = orbitron(16, weight: .bold)
    static let sectionTitle = orbitron(14, weight: .semibold)
    static let bigNumber    = orbitron(28, weight: .heavy)
    static let medNumber    = orbitron(16, weight: .semibold)
    static let buttonText   = orbitron(14, weight: .bold)
    static let tag          = rajdhani(12, weight: .semibold)
    static let body         = rajdhani(15, weight: .regular)
    static let caption      = rajdhani(12, weight: .regular)
    static let date         = rajdhani(13, weight: .regular)
}
