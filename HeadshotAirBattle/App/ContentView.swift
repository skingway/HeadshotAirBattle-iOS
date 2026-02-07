import SwiftUI

/// Navigation route definitions
enum AppRoute: Hashable {
    case mainMenu
    case singlePlayerSetup
    case game(difficulty: String, mode: String, boardSize: Int, airplaneCount: Int)
    case settings
    case profile
    case customMode
    case leaderboard
    case gameHistory
    case battleReport(gameData: GameHistoryEntry)
    case skins
    case achievements
    case onlineMode
    case store
    case privacyPolicy
    case matchmaking(mode: String)
    case roomLobby(gameId: String, roomCode: String?)
    case onlineGame(gameId: String)

    // Hashable conformance for GameHistoryEntry
    func hash(into hasher: inout Hasher) {
        switch self {
        case .mainMenu: hasher.combine("mainMenu")
        case .singlePlayerSetup: hasher.combine("singlePlayerSetup")
        case .game(let d, let m, let b, let a):
            hasher.combine("game"); hasher.combine(d); hasher.combine(m); hasher.combine(b); hasher.combine(a)
        case .settings: hasher.combine("settings")
        case .profile: hasher.combine("profile")
        case .customMode: hasher.combine("customMode")
        case .leaderboard: hasher.combine("leaderboard")
        case .gameHistory: hasher.combine("gameHistory")
        case .battleReport(let g): hasher.combine("battleReport"); hasher.combine(g.id)
        case .skins: hasher.combine("skins")
        case .achievements: hasher.combine("achievements")
        case .onlineMode: hasher.combine("onlineMode")
        case .store: hasher.combine("store")
        case .privacyPolicy: hasher.combine("privacyPolicy")
        case .matchmaking(let m): hasher.combine("matchmaking"); hasher.combine(m)
        case .roomLobby(let g, let r): hasher.combine("roomLobby"); hasher.combine(g); hasher.combine(r)
        case .onlineGame(let g): hasher.combine("onlineGame"); hasher.combine(g)
        }
    }

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MainMenuView(navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .mainMenu:
                        MainMenuView(navigationPath: $navigationPath)
                    case .singlePlayerSetup:
                        SinglePlayerSetupView(navigationPath: $navigationPath)
                    case .game(let difficulty, let mode, let boardSize, let airplaneCount):
                        GameView(
                            navigationPath: $navigationPath,
                            difficulty: difficulty,
                            mode: mode,
                            boardSize: boardSize,
                            airplaneCount: airplaneCount
                        )
                    case .settings:
                        SettingsView(navigationPath: $navigationPath)
                    case .profile:
                        ProfileView(navigationPath: $navigationPath)
                    case .customMode:
                        CustomModeView(navigationPath: $navigationPath)
                    case .leaderboard:
                        LeaderboardView(navigationPath: $navigationPath)
                    case .gameHistory:
                        GameHistoryView(navigationPath: $navigationPath)
                    case .battleReport(let gameData):
                        BattleReportView(navigationPath: $navigationPath, gameData: gameData)
                    case .skins:
                        SkinsView(navigationPath: $navigationPath)
                    case .achievements:
                        AchievementsView(navigationPath: $navigationPath)
                    case .onlineMode:
                        OnlineModeView(navigationPath: $navigationPath)
                    case .store:
                        StoreView(navigationPath: $navigationPath)
                    case .privacyPolicy:
                        PrivacyPolicyView(navigationPath: $navigationPath)
                    case .matchmaking(let mode):
                        MatchmakingView(navigationPath: $navigationPath, mode: mode)
                    case .roomLobby(let gameId, let roomCode):
                        RoomLobbyView(navigationPath: $navigationPath, gameId: gameId, roomCode: roomCode)
                    case .onlineGame(let gameId):
                        OnlineGameView(navigationPath: $navigationPath, gameId: gameId)
                    }
                }
        }
        .task {
            await appViewModel.initialize()
        }
    }
}
