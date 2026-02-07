import SwiftUI

/// Dual board layout for battle phase - shows opponent board (interactive) and player board (reveal)
struct DualBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    private let themeColors = SkinDefinitions.currentThemeColors()

    // 使用 totalTurns 作为刷新触发器，确保每次攻击后视图刷新
    private var refreshTrigger: Int {
        viewModel.totalTurns
    }

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

                // Surrender button
                Button(action: {
                    viewModel.surrender()
                }) {
                    Text("Surrender")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            // Opponent board (attack target)
            VStack(spacing: 4) {
                HStack {
                    Text("Enemy Fleet")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                    Spacer()
                    if let board = viewModel.opponentBoard {
                        Text("Remaining: \(board.getRemainingAirplaneCount())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)

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
                    .id(refreshTrigger) // 强制刷新
                }
            }

            // Player board (reveal own airplanes)
            VStack(spacing: 4) {
                HStack {
                    Text("Your Fleet")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    Spacer()
                    if let board = viewModel.playerBoard {
                        Text("Remaining: \(board.getRemainingAirplaneCount())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)

                if let board = viewModel.playerBoard {
                    BoardGridView(
                        board: board,
                        revealAirplanes: true,
                        isInteractive: false,
                        themeColors: themeColors
                    )
                    .id(refreshTrigger) // 强制刷新
                }
            }

            // Game log
            GameLogView(logs: viewModel.gameLog)
        }
    }
}
