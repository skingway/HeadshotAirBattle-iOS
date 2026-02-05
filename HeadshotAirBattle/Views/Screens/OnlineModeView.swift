import SwiftUI

struct OnlineModeView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var roomCode = ""
    @State private var showJoinRoom = false
    @State private var isCreatingRoom = false
    @State private var isJoiningRoom = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Online Mode")
                    .font(.title.bold())
                    .foregroundColor(.white)

                // Offline mode warning
                if appViewModel.isOfflineMode {
                    Text("Online features require internet connection")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                VStack(spacing: 16) {
                    // Quick Match
                    MenuButton(title: "Quick Match", icon: "bolt.fill") {
                        navigationPath.append(AppRoute.matchmaking(mode: "standard"))
                    }

                    // Create Room
                    MenuButton(title: "Create Room", icon: "plus.circle.fill") {
                        Task { await createRoom() }
                    }
                    .disabled(isCreatingRoom || appViewModel.isOfflineMode)
                    .overlay(
                        isCreatingRoom ? ProgressView().tint(.white) : nil
                    )

                    // Join Room
                    MenuButton(title: "Join Room", icon: "arrow.right.circle.fill") {
                        showJoinRoom = true
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
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
                navigationPath.append(AppRoute.onlineGame(gameId: gameId))
            }
        } catch {
            print("[OnlineModeView] Join room error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to join room: \(error.localizedDescription)"
            }
        }
    }
}
