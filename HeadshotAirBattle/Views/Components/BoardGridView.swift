import SwiftUI

/// Reusable board grid component that renders a game board
struct BoardGridView: View {
    let board: BoardManager
    let revealAirplanes: Bool
    let isInteractive: Bool
    let themeColors: ThemeColors
    var onCellTap: ((Int, Int) -> Void)?

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60 // Padding + label space
        let size = availableWidth / CGFloat(board.size)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 24, height: 16)
                ForEach(0..<board.size, id: \.self) { col in
                    Text(CoordinateSystem.indexToLetter(col))
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: cellSize, height: 16)
                }
            }

            // Grid rows
            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    // Row label
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: 24)

                    // Cells
                    ForEach(0..<board.size, id: \.self) { col in
                        let state = board.getCellState(row: row, col: col, revealAirplanes: revealAirplanes)
                        CellView(
                            state: state,
                            isPlayerBoard: revealAirplanes,
                            showAirplane: revealAirplanes,
                            cellSize: cellSize,
                            themeColors: themeColors,
                            onTap: isInteractive ? { onCellTap?(row, col) } : nil
                        )
                    }
                }
            }
        }
    }
}
