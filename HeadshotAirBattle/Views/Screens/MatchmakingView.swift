import SwiftUI

struct MatchmakingView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = MatchmakingViewModel()
    let mode: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Finding Match...")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.cyan)

                Text("Searching for opponent")
                    .foregroundColor(.gray)

                Text(viewModel.timerText)
                    .font(.title)
                    .foregroundColor(.yellow)
                    .monospacedDigit()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Cancel") {
                    viewModel.cancelMatchmaking()
                    navigationPath.removeLast()
                }
                .foregroundColor(.red)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.startMatchmaking(
                mode: mode,
                userId: appViewModel.userId,
                nickname: appViewModel.nickname,
                stats: appViewModel.userProfile
            )
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.matchedGameId) { gameId in
            if let gameId = gameId {
                navigationPath.removeLast()
                // 匹配成功后跳转到 RoomLobby（和 Android 一致），让双方点击 Ready
                navigationPath.append(AppRoute.roomLobby(gameId: gameId, roomCode: nil))
            }
        }
    }
}
