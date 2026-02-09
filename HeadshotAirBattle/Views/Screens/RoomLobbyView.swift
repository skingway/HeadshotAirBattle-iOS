import SwiftUI

struct RoomLobbyView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = RoomLobbyViewModel()
    let gameId: String
    let roomCode: String?

    var body: some View {
        SciFiBgView {
            VStack(spacing: 24) {
                Text("ROOM LOBBY")
                    .font(AppFonts.pageTitle)
                    .foregroundColor(.white)
                    .tracking(2)

                if let code = roomCode {
                    CardView {
                        VStack(spacing: 8) {
                            Text("ROOM CODE")
                                .font(AppFonts.orbitron(10, weight: .semibold))
                                .foregroundColor(AppColors.textMuted)
                                .tracking(2)
                            HStack(spacing: 12) {
                                Text(code)
                                    .font(AppFonts.orbitron(36, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                                    .onTapGesture {
                                        UIPasteboard.general.string = code
                                    }
                                Button(action: {
                                    let message = "Join my Headshot: Air Battle game!\nRoom Code: \(code)"
                                    let av = UIActivityViewController(activityItems: [message], applicationActivities: nil)
                                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = scene.windows.first?.rootViewController {
                                        var topVC = rootVC
                                        while let presented = topVC.presentedViewController { topVC = presented }
                                        topVC.present(av, animated: true)
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            Text("Tap code to copy")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }

                DividerLine()
                    .padding(.horizontal)

                // Player slots
                VStack(spacing: 12) {
                    PlayerSlot(name: viewModel.player1Name, isReady: viewModel.player1Ready, label: "Host")
                    PlayerSlot(name: viewModel.player2Name, isReady: viewModel.player2Ready, label: "Guest")
                }

                // Game settings
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Game Settings")
                        StatRow(label: "Board Size", value: "\(viewModel.boardSize)\u{00D7}\(viewModel.boardSize)")
                        DividerLine()
                        StatRow(label: "Airplanes", value: "\(viewModel.airplaneCount)")
                    }
                }
                .padding(.horizontal)

                Spacer()

                if viewModel.shouldNavigateToGame {
                    Text("GAME STARTING...")
                        .font(AppFonts.orbitron(14, weight: .bold))
                        .foregroundColor(AppColors.success)
                        .tracking(2)
                }

                // Debug overlay - visible state info
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEBUG: \(viewModel.debugStatus)")
                    Text("nav=\(viewModel.shouldNavigateToGame ? "YES" : "NO") me=\(viewModel.amIReady ? "Y" : "N") role=\(viewModel.myRole)")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.orange)
                .padding(6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(6)

                // Ready and Leave buttons
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.toggleReady()
                    }) {
                        HStack {
                            Image(systemName: viewModel.amIReady ? "checkmark.circle.fill" : "circle")
                            Text("READY")
                                .font(AppFonts.buttonText)
                                .tracking(2)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.amIReady ? AnyShapeStyle(AppColors.success.opacity(0.3)) : AnyShapeStyle(AppColors.primaryGradient))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.amIReady ? AppColors.successBorder : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: {
                        viewModel.leaveRoom()
                        navigationPath.removeLast()
                    }) {
                        Text("LEAVE")
                            .font(AppFonts.buttonText)
                            .tracking(2)
                            .foregroundColor(AppColors.danger)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.dangerDim)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.dangerBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.listenToGame(gameId: gameId, userId: appViewModel.userId)
        }
        .onDisappear {
            viewModel.leaveRoom()
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
            Text(label.uppercased())
                .font(AppFonts.orbitron(9, weight: .semibold))
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .frame(width: 50)

            if let name = name {
                Text(name)
                    .font(AppFonts.rajdhani(16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isReady ? AppColors.success : AppColors.textMuted)
            } else {
                Text("Waiting for player...")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textDark)
                    .italic()
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0, green: 30/255, blue: 60/255).opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.borderLight, lineWidth: 1)
        )
    }
}
