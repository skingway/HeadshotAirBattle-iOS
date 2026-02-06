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
                    VStack(spacing: 20) {
                        if viewModel.opponentNickname.isEmpty {
                            // 等待对手加入
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.cyan)
                            Text("Waiting for opponent to join...")
                                .foregroundColor(.gray)
                        } else {
                            // 对手已加入，显示 Ready 按钮
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.cyan)

                                Text("\(viewModel.opponentNickname) joined!")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                // Ready 状态指示
                                HStack(spacing: 30) {
                                    VStack {
                                        Circle()
                                            .fill(viewModel.isPlayerReady ? Color.green : Color.gray)
                                            .frame(width: 20, height: 20)
                                        Text("You")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }

                                    VStack {
                                        Circle()
                                            .fill(viewModel.opponentReady ? Color.green : Color.gray)
                                            .frame(width: 20, height: 20)
                                        Text("Opponent")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()

                                if viewModel.isPlayerReady {
                                    // 已点击 Ready，等待对手
                                    HStack {
                                        ProgressView()
                                            .tint(.cyan)
                                        Text("Waiting for opponent to ready...")
                                            .foregroundColor(.yellow)
                                    }
                                } else {
                                    // 显示 Ready 按钮
                                    Button(action: {
                                        viewModel.clickReady()
                                    }) {
                                        Text("READY")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 200, height: 60)
                                            .background(Color.green)
                                            .cornerRadius(12)
                                    }
                                }
                            }

                            // 调试信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DEBUG:")
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                Text("myRole: \(viewModel.myRole)")
                                Text("isPlayerReady: \(viewModel.isPlayerReady ? "YES" : "NO")")
                                Text("opponentReady: \(viewModel.opponentReady ? "YES" : "NO")")
                                Text("status: \(viewModel.gameStatus.rawValue)")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
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
                    OnlineBattleView(viewModel: viewModel)

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
