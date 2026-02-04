import SwiftUI

struct OnlineGameView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = OnlineGameViewModel()
    let gameId: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Online Game")
                    .font(.title)
                    .foregroundColor(.white)

                Text("Game ID: \(gameId)")
                    .font(.caption)
                    .foregroundColor(.gray)

                switch viewModel.gameStatus {
                case .deploying:
                    if viewModel.isDeploymentReady {
                        Text("Waiting for opponent...")
                            .foregroundColor(.yellow)
                    } else {
                        DeploymentBoardView(viewModel: viewModel.deploymentHelper)
                    }

                case .battle:
                    DualBoardView(viewModel: viewModel.battleHelper)

                case .finished:
                    VStack(spacing: 16) {
                        Text(viewModel.didWin ? "VICTORY!" : "DEFEAT")
                            .font(.largeTitle.bold())
                            .foregroundColor(viewModel.didWin ? .green : .red)

                        Button("Back to Menu") {
                            navigationPath = NavigationPath()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                default:
                    ProgressView("Connecting...")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Leave") {
                    viewModel.leaveGame()
                    navigationPath = NavigationPath()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            viewModel.joinAndListen(gameId: gameId, userId: appViewModel.userId, nickname: appViewModel.nickname)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}
