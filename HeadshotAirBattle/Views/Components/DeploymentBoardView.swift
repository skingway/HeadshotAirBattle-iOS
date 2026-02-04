import SwiftUI

/// Board view for airplane deployment phase - tap to place, buttons to rotate/random/clear
struct DeploymentBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var selectedDirection: GameConstants.Direction = .up
    private let themeColors = SkinDefinitions.currentThemeColors()

    private var cellSize: CGFloat {
        let boardSize = viewModel.playerBoard?.size ?? 10
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 60
        let size = availableWidth / CGFloat(boardSize)
        return min(max(size, GameConstants.GridDisplay.minCellSize), GameConstants.GridDisplay.maxCellSize)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Deploy Your Fleet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("\(viewModel.deployedAirplanes.count)/\(viewModel.playerBoard?.airplaneCount ?? 3) airplanes placed")
                .font(.caption)
                .foregroundColor(.gray)

            // Board
            if let board = viewModel.playerBoard {
                boardGrid(board: board)
            }

            // Airplane preview
            AirplaneShapeView(direction: selectedDirection, cellSize: 20)
                .frame(height: 100)

            // Controls
            HStack(spacing: 16) {
                Button(action: rotateDirection) {
                    Label("Rotate", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.deployAirplanesRandomly() }) {
                    Label("Random", systemImage: "dice.fill")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.clearDeployment() }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            // Confirm button
            if viewModel.isDeploymentComplete() {
                Button("Start Battle") {
                    viewModel.confirmDeployment()
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func boardGrid(board: BoardManager) -> some View {
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

            ForEach(0..<board.size, id: \.self) { row in
                HStack(spacing: 0) {
                    Text("\(row + 1)")
                        .font(.system(size: min(cellSize * 0.4, 10)))
                        .foregroundColor(.gray)
                        .frame(width: 24)

                    ForEach(0..<board.size, id: \.self) { col in
                        let hasAirplane = board.hasAirplaneAt(row: row, col: col)
                        Rectangle()
                            .fill(hasAirplane ? Color(hex: SkinDefinitions.currentSkinColor()) : Color(hex: themeColors.cellEmpty))
                            .frame(width: cellSize, height: cellSize)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(hex: themeColors.gridLine), lineWidth: 0.5)
                            )
                            .overlay(
                                headIndicator(board: board, row: row, col: col)
                            )
                            .onTapGesture {
                                handleCellTap(row: row, col: col)
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func headIndicator(board: BoardManager, row: Int, col: Int) -> some View {
        if let airplane = board.getAirplaneAt(row: row, col: col),
           airplane.getCellType(row: row, col: col) == .head {
            Circle()
                .fill(Color.white)
                .frame(width: cellSize * 0.4, height: cellSize * 0.4)
        } else {
            EmptyView()
        }
    }

    private func handleCellTap(row: Int, col: Int) {
        guard let board = viewModel.playerBoard else { return }

        // If there's an airplane here, remove it
        if let airplane = board.getAirplaneAt(row: row, col: col) {
            viewModel.removeAirplane(id: airplane.id)
            return
        }

        // Try to place an airplane
        _ = viewModel.addAirplane(headRow: row, headCol: col, direction: selectedDirection)
    }

    private func rotateDirection() {
        let allDirs = GameConstants.Direction.allCases
        if let index = allDirs.firstIndex(of: selectedDirection) {
            selectedDirection = allDirs[(index + 1) % allDirs.count]
        }
    }
}
