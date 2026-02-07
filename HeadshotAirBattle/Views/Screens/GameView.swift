import SwiftUI

struct GameView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = GameViewModel()
    let difficulty: String
    let mode: String
    let boardSize: Int
    let airplaneCount: Int

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                switch viewModel.phase {
                case .deployment:
                    DeploymentBoardView(viewModel: viewModel)

                case .countdown:
                    CountdownView {
                        viewModel.startBattle()
                    }

                case .battle:
                    DualBoardView(viewModel: viewModel)

                case .gameOver:
                    gameOverView
                        .onAppear {
                            AdService.shared.onGameFinished()
                        }

                default:
                    ProgressView("Loading...")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.phase == .gameOver || viewModel.phase == .deployment {
                    Button("Back") {
                        navigationPath.removeLast()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            viewModel.setup(
                difficulty: difficulty,
                mode: mode,
                boardSize: boardSize,
                airplaneCount: airplaneCount,
                userId: appViewModel.userId
            )
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text(viewModel.didPlayerWin ? "VICTORY!" : "DEFEAT")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(viewModel.didPlayerWin ? .green : .red)

            VStack(spacing: 8) {
                Text("Turns: \(viewModel.totalTurns)")
                if let stats = viewModel.playerStats {
                    Text("Hits: \(stats.hits) | Misses: \(stats.misses) | Kills: \(stats.kills)")
                }
                let accuracy = viewModel.playerAccuracy
                Text("Accuracy: \(String(format: "%.1f", accuracy))%")
            }
            .font(.body)
            .foregroundColor(.gray)

            HStack(spacing: 16) {
                Button("Play Again") {
                    viewModel.setup(
                        difficulty: difficulty,
                        mode: mode,
                        boardSize: boardSize,
                        airplaneCount: airplaneCount,
                        userId: appViewModel.userId
                    )
                }
                .buttonStyle(.borderedProminent)

                Button("Main Menu") {
                    navigationPath.removeLast()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
