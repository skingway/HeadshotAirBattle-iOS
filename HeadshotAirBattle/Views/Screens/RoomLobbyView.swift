import SwiftUI

struct RoomLobbyView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = RoomLobbyViewModel()
    let gameId: String
    let roomCode: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Room Lobby")
                    .font(.title.bold())
                    .foregroundColor(.white)

                if let code = roomCode {
                    VStack(spacing: 8) {
                        Text("Room Code")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(code)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .onTapGesture {
                                UIPasteboard.general.string = code
                            }
                        Text("Tap to copy")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Divider().background(Color.gray)

                // 玩家卡片
                VStack(spacing: 12) {
                    PlayerSlot(name: viewModel.player1Name, isReady: viewModel.player1Ready, label: "Host")
                    PlayerSlot(name: viewModel.player2Name, isReady: viewModel.player2Ready, label: "Guest")
                }

                // 游戏设置显示
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Settings")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    HStack {
                        Text("Board Size:")
                            .foregroundColor(.gray)
                        Text("\(viewModel.boardSize)×\(viewModel.boardSize)")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Airplanes:")
                            .foregroundColor(.gray)
                        Text("\(viewModel.airplaneCount)")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                Spacer()

                if viewModel.shouldNavigateToGame {
                    Text("Game starting...")
                        .foregroundColor(.green)
                }

                #if DEBUG
                // 调试信息（仅在调试模式显示）
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEBUG:")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Text("myRole: \(viewModel.myRole)")
                    Text("p1Ready: \(viewModel.player1Ready ? "YES" : "NO")")
                    Text("p2Ready: \(viewModel.player2Ready ? "YES" : "NO")")
                    Text("amIReady: \(viewModel.amIReady ? "YES" : "NO")")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                #endif

                // Ready 和 Leave 按钮
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.toggleReady()
                    }) {
                        HStack {
                            Image(systemName: viewModel.amIReady ? "checkmark.circle.fill" : "circle")
                            Text(viewModel.amIReady ? "Ready" : "Ready")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.amIReady ? Color.green : Color.blue)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.leaveRoom()
                        navigationPath.removeLast()
                    }) {
                        Text("Leave Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.listenToGame(gameId: gameId, userId: appViewModel.userId)
        }
        .onChange(of: viewModel.shouldNavigateToGame) { shouldNavigate in
            if shouldNavigate {
                navigationPath.removeLast()
                navigationPath.append(AppRoute.onlineGame(gameId: gameId))
            }
        }
    }
}

struct PlayerSlot: View {
    let name: String?
    let isReady: Bool
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50)

            if let name = name {
                Text(name)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isReady ? .green : .gray)
            } else {
                Text("Waiting for player...")
                    .foregroundColor(.gray.opacity(0.5))
                    .italic()
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
