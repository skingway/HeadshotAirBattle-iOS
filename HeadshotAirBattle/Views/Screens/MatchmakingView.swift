import SwiftUI

struct MatchmakingView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = MatchmakingViewModel()
    let mode: String
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        SciFiBgView {
            VStack(spacing: 24) {
                Text("FINDING MATCH...")
                    .font(AppFonts.orbitron(18, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(2)

                // Pulsing radar icon
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.accent)
                    .scaleEffect(pulseScale)
                    .shadow(color: AppColors.accentGlow, radius: 15)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                        }
                    }

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.accent)

                Text("Searching for opponent")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.timerText)
                    .font(AppFonts.orbitron(28, weight: .bold))
                    .foregroundColor(AppColors.gold)
                    .monospacedDigit()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.danger)
                }

                Button(action: {
                    viewModel.cancelMatchmaking()
                    navigationPath.removeLast()
                }) {
                    Text("CANCEL")
                        .font(AppFonts.buttonText)
                        .tracking(2)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(AppColors.dangerDim)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColors.dangerBorder, lineWidth: 1)
                        )
                }
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
                navigationPath.append(AppRoute.roomLobby(gameId: gameId, roomCode: nil))
            }
        }
    }
}
