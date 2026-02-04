import SwiftUI

/// Renders an airplane shape preview with the given direction
struct AirplaneShapeView: View {
    let direction: GameConstants.Direction
    let cellSize: CGFloat

    var body: some View {
        let cells = Airplane.calculateCells(headRow: 3, headCol: 3, direction: direction)

        let minRow = cells.map(\.row).min() ?? 0
        let minCol = cells.map(\.col).min() ?? 0
        let maxRow = cells.map(\.row).max() ?? 0
        let maxCol = cells.map(\.col).max() ?? 0

        let rows = maxRow - minRow + 1
        let cols = maxCol - minCol + 1

        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<cols, id: \.self) { c in
                        let row = r + minRow
                        let col = c + minCol
                        let cell = cells.first { $0.row == row && $0.col == col }

                        if let cell = cell {
                            Rectangle()
                                .fill(cellColor(for: cell.type))
                                .frame(width: cellSize, height: cellSize)
                                .cornerRadius(cell.type == .head ? cellSize / 2 : 2)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private func cellColor(for type: AirplaneCellType) -> Color {
        let skinColor = Color(hex: SkinDefinitions.currentSkinColor())
        switch type {
        case .head:
            return .white
        case .body:
            return skinColor
        case .wing:
            return skinColor.opacity(0.8)
        case .tail:
            return skinColor.opacity(0.6)
        }
    }
}
