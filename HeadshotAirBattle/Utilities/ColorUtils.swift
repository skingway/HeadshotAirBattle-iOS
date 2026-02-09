import SwiftUI

struct CellEffects {
    struct GradientColors {
        let start: Color
        let end: Color
    }

    struct EmptyEffect {
        let baseColor: Color
        let borderColor: Color
    }

    struct AirplaneEffect {
        let gradient: GradientColors
        let glowColor: Color
    }

    struct HeadEffect {
        let gradient: GradientColors
        let reticleColor: Color
    }

    struct HitEffect {
        let gradient: GradientColors
        let glowColor: Color
        let pulseColor: Color
    }

    struct KilledEffect {
        let gradient: GradientColors
        let glowColor: Color
        let xColor: Color
    }

    struct MissEffect {
        let baseColor: Color
        let dotColor: Color
    }

    let empty: EmptyEffect
    let airplane: AirplaneEffect
    let head: HeadEffect
    let hit: HitEffect
    let killed: KilledEffect
    let miss: MissEffect
}

enum ColorUtils {
    static func generateCellEffects(from themeColors: ThemeColors) -> CellEffects {
        let emptyColor = Color(hex: themeColors.cellEmpty)
        let airplaneColor = Color(hex: themeColors.cellAirplane)
        let hitColor = Color(hex: themeColors.cellHit)
        let missColor = Color(hex: themeColors.cellMiss)
        let killedColor = Color(hex: themeColors.cellKilled)
        let gridColor = Color(hex: themeColors.gridLine)

        return CellEffects(
            empty: CellEffects.EmptyEffect(
                baseColor: emptyColor,
                borderColor: gridColor
            ),
            airplane: CellEffects.AirplaneEffect(
                gradient: CellEffects.GradientColors(
                    start: lighten(airplaneColor, by: 0.2),
                    end: darken(airplaneColor, by: 0.15)
                ),
                glowColor: airplaneColor.opacity(0.4)
            ),
            head: CellEffects.HeadEffect(
                gradient: CellEffects.GradientColors(
                    start: lighten(airplaneColor, by: 0.3),
                    end: airplaneColor
                ),
                reticleColor: lighten(airplaneColor, by: 0.5)
            ),
            hit: CellEffects.HitEffect(
                gradient: CellEffects.GradientColors(
                    start: lighten(hitColor, by: 0.15),
                    end: darken(hitColor, by: 0.1)
                ),
                glowColor: hitColor.opacity(0.6),
                pulseColor: lighten(hitColor, by: 0.3).opacity(0.5)
            ),
            killed: CellEffects.KilledEffect(
                gradient: CellEffects.GradientColors(
                    start: lighten(killedColor, by: 0.15),
                    end: darken(killedColor, by: 0.15)
                ),
                glowColor: killedColor.opacity(0.6),
                xColor: .white
            ),
            miss: CellEffects.MissEffect(
                baseColor: missColor,
                dotColor: .white.opacity(0.6)
            )
        )
    }

    static func lighten(_ color: Color, by amount: Double) -> Color {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: min(r + (1.0 - r) * amount, 1.0),
            green: min(g + (1.0 - g) * amount, 1.0),
            blue: min(b + (1.0 - b) * amount, 1.0),
            opacity: a
        )
    }

    static func darken(_ color: Color, by amount: Double) -> Color {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: max(r * (1.0 - amount), 0.0),
            green: max(g * (1.0 - amount), 0.0),
            blue: max(b * (1.0 - amount), 0.0),
            opacity: a
        )
    }
}
