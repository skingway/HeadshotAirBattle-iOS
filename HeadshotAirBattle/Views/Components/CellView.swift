import SwiftUI

/// Renders a single cell on the game board
struct CellView: View {
    let state: GameConstants.CellState
    let isPlayerBoard: Bool
    let showAirplane: Bool
    let cellSize: CGFloat
    let themeColors: ThemeColors
    var onTap: (() -> Void)?

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)
            .overlay(cellOverlay)
            .overlay(
                Rectangle()
                    .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
            )
            .onTapGesture {
                onTap?()
            }
    }

    private var cellColor: Color {
        switch state {
        case .empty:
            return Color(hex: themeColors.cellEmpty)
        case .airplane:
            return showAirplane ? Color(hex: themeColors.cellAirplane) : Color(hex: themeColors.cellEmpty)
        case .hit:
            return Color(hex: themeColors.cellHit)
        case .miss:
            return Color(hex: themeColors.cellMiss)
        case .killed:
            return Color(hex: themeColors.cellKilled)
        }
    }

    @ViewBuilder
    private var cellOverlay: some View {
        switch state {
        case .hit:
            Image(systemName: "flame.fill")
                .font(.system(size: cellSize * 0.5))
                .foregroundColor(.orange)
        case .miss:
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: cellSize * 0.3, height: cellSize * 0.3)
        case .killed:
            Image(systemName: "xmark")
                .font(.system(size: cellSize * 0.6, weight: .bold))
                .foregroundColor(.white)
        case .airplane where showAirplane:
            Circle()
                .fill(Color(hex: SkinDefinitions.currentSkinColor()))
                .frame(width: cellSize * 0.6, height: cellSize * 0.6)
        default:
            EmptyView()
        }
    }
}
