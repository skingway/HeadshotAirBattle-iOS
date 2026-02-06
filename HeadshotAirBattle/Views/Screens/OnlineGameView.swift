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
                // 顶部信息栏
                HStack {
                    VStack(alignment: .leading) {
                        Text("Online Game")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("vs \(viewModel.opponentNickname.isEmpty ? "Waiting..." : viewModel.opponentNickname)")
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                    Text(gameId.prefix(8))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                .padding(.horizontal)

                switch viewModel.gameStatus {
                case .waiting:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.cyan)
                        Text("Waiting for opponent to join...")
                            .foregroundColor(.gray)
                    }

                case .deploying:
                    VStack(spacing: 12) {
                        // 状态指示
                        HStack {
                            Circle()
                                .fill(viewModel.isDeploymentReady ? Color.green : Color.yellow)
                                .frame(width: 10, height: 10)
                            Text(viewModel.isDeploymentReady ? "Ready" : "Deploying...")
                                .foregroundColor(.white)
                            Spacer()
                            Circle()
                                .fill(viewModel.opponentDeploymentReady ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            Text("Opponent: \(viewModel.opponentDeploymentReady ? "Ready" : "Deploying")")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        if viewModel.isDeploymentReady {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                Text("Waiting for opponent to deploy...")
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                        } else {
                            // 部署界面
                            DeploymentBoardView(viewModel: viewModel.deploymentHelper)
                                .onChange(of: viewModel.deploymentHelper.phase) { phase in
                                    if phase == .countdown || phase == .battle {
                                        // 用户确认了部署
                                        viewModel.confirmDeployment()
                                    }
                                }
                        }
                    }

                case .battle:
                    VStack(spacing: 8) {
                        // 回合指示
                        HStack {
                            Circle()
                                .fill(viewModel.isMyTurn ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(viewModel.isMyTurn ? "Your Turn" : "Opponent's Turn")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        DualBoardView(viewModel: viewModel.battleHelper)

                        // 游戏日志
                        GameLogView(logs: viewModel.gameLog)
                    }

                case .finished:
                    VStack(spacing: 20) {
                        Image(systemName: viewModel.didWin ? "trophy.fill" : "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(viewModel.didWin ? .yellow : .red)

                        Text(viewModel.didWin ? "VICTORY!" : "DEFEAT")
                            .font(.largeTitle.bold())
                            .foregroundColor(viewModel.didWin ? .green : .red)

                        Button("Back to Menu") {
                            navigationPath = NavigationPath()
                        }
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                    }
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
