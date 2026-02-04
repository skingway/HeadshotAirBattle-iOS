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

                VStack(spacing: 12) {
                    PlayerSlot(name: viewModel.player1Name, isReady: viewModel.player1Ready, label: "Host")
                    PlayerSlot(name: viewModel.player2Name, isReady: viewModel.player2Ready, label: "Guest")
                }

                Spacer()

                if viewModel.shouldNavigateToGame {
                    Text("Game starting...")
                        .foregroundColor(.green)
                }

                Button("Leave Room") {
                    viewModel.leaveRoom()
                    navigationPath.removeLast()
                }
                .foregroundColor(.red)
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
