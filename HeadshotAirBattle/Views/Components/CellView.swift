import SwiftUI

/// Renders a single cell on the game board
struct CellView: View {
    let state: GameConstants.CellState
    let isPlayerBoard: Bool
    let showAirplane: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors

    var onTap: (() -> Void)?

    @State private var hitPulse: Bool = false

    private var effects: CellEffects {
        ColorUtils.generateCellEffects(from: themeColors)
    }

    var body: some View {
        ZStack {
            cellBackground
            cellOverlay
        }
        .frame(width: cellSize, height: cellSize)
        .overlay(
            Rectangle()
                .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
        )
        .onTapGesture {
            onTap?()
        }
    }

    @ViewBuilder
    private var cellBackground: some View {
        switch state {
        case .empty:
            Rectangle()
                .fill(effects.empty.baseColor)

        case .airplane:
            if showAirplane {
                LinearGradient(
                    colors: [effects.airplane.gradient.start, effects.airplane.gradient.end],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .shadow(color: effects.airplane.glowColor, radius: 3, x: 0, y: 0)
            } else {
                Rectangle()
                    .fill(effects.empty.baseColor)
            }

        case .hit:
            LinearGradient(
                colors: [effects.hit.gradient.start, effects.hit.gradient.end],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Rectangle()
                    .fill(effects.hit.pulseColor)
                    .opacity(hitPulse ? 0.6 : 0.0)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    hitPulse = true
                }
            }

        case .miss:
            Rectangle()
                .fill(effects.miss.baseColor)

        case .killed:
            LinearGradient(
                colors: [effects.killed.gradient.start, effects.killed.gradient.end],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .shadow(color: effects.killed.glowColor, radius: 4, x: 0, y: 0)
        }
    }

    @ViewBuilder
    private var cellOverlay: some View {
        switch state {
        case .hit:
            Image(systemName: "flame.fill")
                .font(.system(size: cellSize * 0.5))
                .foregroundColor(.orange)
                .shadow(color: effects.hit.glowColor, radius: 3)

        case .miss:
            Circle()
                .fill(effects.miss.dotColor)
                .frame(width: cellSize * 0.25, height: cellSize * 0.25)

        case .killed:
            Image(systemName: "xmark")
                .font(.system(size: cellSize * 0.6, weight: .bold))
                .foregroundColor(effects.killed.xColor)
                .shadow(color: effects.killed.glowColor, radius: 4)

        case .airplane where showAirplane:
            Circle()
                .fill(Color(hex: SkinDefinitions.currentSkinColor()))
                .frame(width: cellSize * 0.6, height: cellSize * 0.6)

        default:
            EmptyView()
        }
    }
}
