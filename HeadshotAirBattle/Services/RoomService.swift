import Foundation
import FirebaseDatabase

/// Manages private room creation and joining via room codes
class RoomService {
    static let shared = RoomService()

    private let db = Database.database(url: "https://airplane-battle-7a3fd-default-rtdb.firebaseio.com")
    private let roomCodeChars = GameConstants.roomCodeCharacters

    private init() {}

    // MARK: - Generate Room Code

    func generateRoomCode() -> String {
        let chars = Array(roomCodeChars)
        return String((0..<GameConstants.roomCodeLength).map { _ in chars.randomElement()! })
    }

    // MARK: - Create Room

    func createRoom(hostId: String, hostNickname: String, mode: String = "standard",
                    boardSize: Int = 10, airplaneCount: Int = 3) async throws -> (gameId: String, roomCode: String) {
        // Clean up previous rooms for this user
        await cleanupUserRooms(hostId: hostId)

        // Generate unique room code (max 10 attempts)
        var roomCode = ""
        for _ in 0..<10 {
            roomCode = generateRoomCode()
            let exists = try await roomCodeExists(roomCode)
            if !exists { break }
        }

        // Create game
        let gameId = try await MultiplayerService.shared.createGame(
            hostId: hostId,
            hostNickname: hostNickname,
            gameType: "privateRoom",
            mode: mode,
            boardSize: boardSize,
            airplaneCount: airplaneCount,
            roomCode: roomCode
        )

        // Save room code mapping
        let roomData: [String: Any] = [
            "gameId": gameId,
            "hostId": hostId,
            "createdAt": Date().millisecondsSince1970,
            "expiresAt": Date().millisecondsSince1970 + 3600000 // 1 hour
        ]

        let roomRef = db.reference().child("roomCodes").child(roomCode)
        try await roomRef.setValue(roomData)

        // Auto-delete on disconnect
        roomRef.onDisconnectRemoveValue()

        return (gameId, roomCode)
    }

    // MARK: - Join Room

    func joinRoom(roomCode: String, userId: String, nickname: String) async throws -> String {
        let normalizedCode = roomCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidRoomCode(normalizedCode) else {
            throw RoomError.invalidCode
        }

        // Lookup room
        let roomRef = db.reference().child("roomCodes").child(normalizedCode)
        let snapshot = try await roomRef.getData()

        guard let data = snapshot.value as? [String: Any],
              let gameId = data["gameId"] as? String else {
            throw RoomError.roomNotFound
        }

        // Check expiry
        if let expiresAt = data["expiresAt"] as? Double,
           Date().millisecondsSince1970 > expiresAt {
            throw RoomError.roomExpired
        }

        // Join the game
        try await MultiplayerService.shared.joinGame(gameId: gameId, userId: userId, nickname: nickname)

        return gameId
    }

    // MARK: - Delete Room

    func deleteRoom(roomCode: String) async throws {
        try await db.reference().child("roomCodes").child(roomCode).removeValue()
    }

    // MARK: - Validation

    func isValidRoomCode(_ code: String) -> Bool {
        guard code.count == GameConstants.roomCodeLength else { return false }
        let validChars = Set(roomCodeChars)
        return code.allSatisfy { validChars.contains($0) }
    }

    // MARK: - Helpers

    private func roomCodeExists(_ code: String) async throws -> Bool {
        let snapshot = try await db.reference().child("roomCodes").child(code).getData()
        return snapshot.exists()
    }

    private func cleanupUserRooms(hostId: String) async {
        // Query and delete old rooms by this host
        do {
            let snapshot = try await db.reference().child("roomCodes")
                .queryOrdered(byChild: "hostId")
                .queryEqual(toValue: hostId)
                .getData()

            guard let rooms = snapshot.value as? [String: Any] else { return }
            for (code, _) in rooms {
                try? await db.reference().child("roomCodes").child(code).removeValue()
            }
        } catch {
            print("[RoomService] Cleanup error: \(error.localizedDescription)")
        }
    }
}

enum RoomError: LocalizedError {
    case invalidCode
    case roomNotFound
    case roomExpired
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid room code format"
        case .roomNotFound: return "Room not found"
        case .roomExpired: return "Room has expired"
        case .creationFailed: return "Failed to create room"
        }
    }
}
