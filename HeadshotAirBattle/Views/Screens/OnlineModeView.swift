import SwiftUI

struct OnlineModeView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var roomCode = ""
    @State private var showJoinRoom = false
    @State private var isCreatingRoom = false
    @State private var isJoiningRoom = false
    @State private var errorMessage: String?
    @State private var isAppeared = false

    var body: some View {
        SciFiBgView {
            VStack(spacing: 24) {
                Text("ONLINE MODE")
                    .font(AppFonts.pageTitle)
                    .foregroundColor(.white)
                    .tracking(2)

                // Offline mode warning
                if appViewModel.isOfflineMode {
                    Text("Online features require internet connection")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.warning)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.warning.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                        )
                }

                Spacer()

                VStack(spacing: 14) {
                    PrimaryButton(icon: "\u{26A1}", title: "Quick Match") {
                        navigationPath.append(AppRoute.matchmaking(mode: "standard"))
                    }

                    SecondaryButton(icon: "\u{2795}", title: "Create Room") {
                        Task { await createRoom() }
                    }
                    .disabled(isCreatingRoom || appViewModel.isOfflineMode)
                    .overlay(
                        isCreatingRoom ? ProgressView().tint(AppColors.accent) : nil
                    )

                    TertiaryButton(icon: "\u{27A1}\u{FE0F}", title: "Join Room") {
                        showJoinRoom = true
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                if let error = errorMessage {
                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.danger)
                }
            }
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isAppeared = true
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Join Room", isPresented: $showJoinRoom) {
            TextField("Room Code", text: $roomCode)
                .textInputAutocapitalization(.characters)
            Button("Join") {
                Task { await joinRoom() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func createRoom() async {
        guard !isCreatingRoom else { return }

        if appViewModel.isOfflineMode {
            errorMessage = "Cannot create room in offline mode"
            return
        }

        isCreatingRoom = true
        errorMessage = nil
        defer { isCreatingRoom = false }

        do {
            let (gameId, code) = try await RoomService.shared.createRoom(
                hostId: appViewModel.userId,
                hostNickname: appViewModel.nickname
            )

            await MainActor.run {
                navigationPath.append(AppRoute.roomLobby(gameId: gameId, roomCode: code))
            }
        } catch {
            print("[OnlineModeView] Create room error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to create room: \(error.localizedDescription)"
            }
        }
    }

    private func joinRoom() async {
        guard !isJoiningRoom else { return }

        let code = roomCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard RoomService.shared.isValidRoomCode(code) else {
            errorMessage = "Invalid room code format (must be 6 characters)"
            return
        }

        isJoiningRoom = true
        errorMessage = nil
        defer { isJoiningRoom = false }

        do {
            let gameId = try await RoomService.shared.joinRoom(
                roomCode: code,
                userId: appViewModel.userId,
                nickname: appViewModel.nickname
            )

            await MainActor.run {
                navigationPath.append(AppRoute.roomLobby(gameId: gameId, roomCode: code))
            }
        } catch {
            print("[OnlineModeView] Join room error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to join room: \(error.localizedDescription)"
            }
        }
    }
}
