import SwiftUI

/// Dual board layout for battle phase - shows opponent board (interactive) and player board (reveal)
struct DualBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    private let themeColors = SkinDefinitions.currentThemeColors()

    var body: some View {
        VStack(spacing: 8) {
            // Turn indicator
            HStack {
                Circle()
                    .fill(viewModel.isPlayerTurn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isPlayerTurn ? "Your Turn" : "Opponent's Turn")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Timer
                TurnTimerView(timeRemaining: viewModel.turnTimeRemaining)
            }
            .padding(.horizontal)

            // Opponent board (attack target)
            VStack(spacing: 4) {
                Text("Enemy Fleet")
                    .font(.caption.bold())
                    .foregroundColor(.cyan)

                if let board = viewModel.opponentBoard {
                    BoardGridView(
                        board: board,
                        revealAirplanes: false,
                        isInteractive: viewModel.isPlayerTurn,
                        themeColors: themeColors,
                        onCellTap: { row, col in
                            viewModel.playerAttack(row: row, col: col)
                        }
                    )
                }
            }

            // Player board (reveal own airplanes)
            VStack(spacing: 4) {
                Text("Your Fleet")
                    .font(.caption.bold())
                    .foregroundColor(.green)

                if let board = viewModel.playerBoard {
                    BoardGridView(
                        board: board,
                        revealAirplanes: true,
                        isInteractive: false,
                        themeColors: themeColors
                    )
                }
            }

            // Game log
            GameLogView(logs: viewModel.gameLog)
        }
    }
}
