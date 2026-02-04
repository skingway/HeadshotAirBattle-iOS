import SwiftUI

struct OnlineModeView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var roomCode = ""
    @State private var showJoinRoom = false
    @State private var isCreatingRoom = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Online Mode")
                    .font(.title.bold())
                    .foregroundColor(.white)

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
        isCreatingRoom = true
        defer { isCreatingRoom = false }

        do {
            let roomService = RoomService.shared
            let (gameId, code) = try await roomService.createRoom(
                hostId: appViewModel.userId,
                hostNickname: appViewModel.nickname
            )
            navigationPath.append(AppRoute.roomLobby(gameId: gameId, roomCode: code))
        } catch {
            errorMessage = "Failed to create room: \(error.localizedDescription)"
        }
    }

    private func joinRoom() async {
        let code = roomCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard RoomService.shared.isValidRoomCode(code) else {
            errorMessage = "Invalid room code format"
            return
        }

        do {
            let gameId = try await RoomService.shared.joinRoom(
                roomCode: code,
                userId: appViewModel.userId,
                nickname: appViewModel.nickname
            )
            navigationPath.append(AppRoute.onlineGame(gameId: gameId))
        } catch {
            errorMessage = "Failed to join room: \(error.localizedDescription)"
        }
    }
}
