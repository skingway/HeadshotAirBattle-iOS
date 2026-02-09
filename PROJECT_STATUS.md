# HeadshotAirBattle iOS - Project Status

## Last Updated: 2026-02-07

## Project Overview
iOS native (Swift/SwiftUI) version of HeadshotAirBattle, a battleship-style airplane combat game.
Android version (React Native): https://github.com/skingway/HeadshotAirBattle

---

## Build & Install

见下方 **Device Info** 中的最新命令。

---

## Feature Comparison: iOS vs Android

### COMPLETED (iOS matches Android)

| Feature | Status | Key Files |
|---------|--------|-----------|
| Main Menu | Done | `MainMenuView.swift` |
| Single Player (Easy/Medium/Hard) | Done | `GameView.swift`, `GameViewModel.swift` |
| Custom Mode (board size, airplane count) | Done | `CustomModeView.swift`, `SinglePlayerSetupView.swift` |
| AI Strategy (Easy/Medium/Hard) | Done | `AIStrategy.swift`, `AIStrategyHard.swift` |
| Deployment Phase (drag/drop airplanes) | Done | `DeploymentBoardView.swift` |
| Battle Phase (dual board, attack) | Done | `DualBoardView.swift`, `BoardGridView.swift` |
| Turn Timer (5 sec) | Done | `TurnTimerView.swift` |
| Countdown (3 sec before battle) | Done | `CountdownView.swift` |
| Game Over Screen | Done | `GameView.swift` |
| Profile (nickname edit, 30-day cooldown) | Done | `ProfileView.swift`, `ProfileViewModel.swift` |
| Achievements System | Done | `AchievementsView.swift`, `AchievementService.swift` |
| Skins / Themes | Done | `SkinsView.swift`, `SkinService.swift`, `SkinDefinitions.swift` |
| Settings (audio toggle, volume) | Done | `SettingsView.swift`, `SettingsViewModel.swift` |
| Leaderboard (winRate/wins/totalGames) | Done | `LeaderboardView.swift`, `LeaderboardViewModel.swift` |
| Game History (AI + online) | Done | `GameHistoryView.swift`, `GameHistoryViewModel.swift` |
| Firebase Auth (anonymous) | Done | `AuthService.swift` |
| Firebase Firestore (stats/history) | Done | `StatisticsService.swift` |
| Firebase Realtime DB (online games) | Done | `MultiplayerService.swift` |
| Online: Private Room (create/join) | Done | `OnlineModeView.swift`, `RoomService.swift` |
| Online: Room Lobby (ready flow) | Done | `RoomLobbyView.swift`, `RoomLobbyViewModel.swift` |
| Online: Quick Match | Done | `MatchmakingView.swift`, `MatchmakingViewModel.swift` |
| Online: Deployment Phase | Done | `OnlineGameView.swift` |
| Online: Battle Phase | Done | `OnlineBattleView.swift`, `OnlineGameViewModel.swift` |
| Online: Attack (hit/miss/kill) | Done | `OnlineGameViewModel.swift` attack() |
| Online: Turn switching (userId) | Done | currentTurn uses userId (matches Android) |
| Online: Surrender | Done | `OnlineGameViewModel.swift` surrender() |
| Online: Game Result (win/loss) | Done | handleStatusChange .finished |
| Online: History Recording | Done | saveOnlineGameResult() |
| Online: Stats Update | Done | StatisticsService.updateStatistics() |
| Online: Achievement Triggers | Done | checkGameEndAchievements() + checkStatsAchievements() |
| Cross-platform Quick Match | Tested | iOS-iOS and iOS-Android tested successfully |
| Haptic Feedback (miss/hit/kill) | Done | `AudioService.swift` playVibration() |
| Haptic: Victory/Defeat patterns | Done | `AudioService.swift` |
| Audio: SFX framework | Done | `AudioService.swift` playSFX() |
| Audio: BGM framework | Done | `AudioService.swift` playBGM()/stopBGM() |
| Disconnect Handling | Done | presence tracking via Firebase |

### PENDING / KNOWN ISSUES

No known critical issues! All major features are complete and tested.

---

## Architecture

```
HeadshotAirBattle/
├── App/                    # App entry point, navigation
│   ├── HeadshotAirBattleApp.swift
│   └── ContentView.swift   # NavigationStack + route definitions
├── Models/
│   ├── Airplane.swift       # 10-cell airplane with hit detection
│   ├── BoardManager.swift   # Grid management, attack processing
│   ├── CoordinateSystem.swift
│   ├── GameConstants.swift  # All enums, constants, config
│   ├── GameState.swift      # GameResult struct
│   ├── FirebaseModels.swift # Statistics, GameHistoryEntry, etc.
│   ├── SkinDefinitions.swift
│   └── AchievementDefinitions.swift
├── Services/
│   ├── AudioService.swift       # SFX, BGM, haptic feedback
│   ├── AuthService.swift        # Firebase anonymous auth
│   ├── StatisticsService.swift  # Stats, history, leaderboard
│   ├── AchievementService.swift
│   ├── MultiplayerService.swift # Online game CRUD
│   ├── MatchmakingService.swift
│   ├── RoomService.swift        # Private room codes
│   ├── SkinService.swift
│   └── FirebaseService.swift
├── ViewModels/
│   ├── GameViewModel.swift          # Single player game logic
│   ├── OnlineGameViewModel.swift    # Online PvP game logic
│   ├── MatchmakingViewModel.swift   # Quick match
│   ├── RoomLobbyViewModel.swift     # Room ready flow
│   ├── AppViewModel.swift           # Global app state
│   └── ... (other VMs)
├── Views/
│   ├── Screens/
│   │   ├── MainMenuView.swift
│   │   ├── GameView.swift           # Single player
│   │   ├── OnlineGameView.swift     # Online wrapper
│   │   ├── OnlineModeView.swift     # Online menu
│   │   ├── MatchmakingView.swift
│   │   ├── RoomLobbyView.swift
│   │   └── ... (other screens)
│   └── Components/
│       ├── OnlineBattleView.swift   # Online battle board
│       ├── DualBoardView.swift      # AI battle board
│       ├── DeploymentBoardView.swift
│       ├── BoardGridView.swift
│       ├── CellView.swift
│       ├── CountdownView.swift
│       └── TurnTimerView.swift
├── AI/
│   ├── AIStrategy.swift        # Easy + Medium
│   └── AIStrategyHard.swift    # Hard (Ultra V2)
├── Utilities/
│   └── Extensions.swift
└── Resources/
    ├── Sounds/                 # EMPTY - needs mp3 files
    └── Assets.xcassets/
```

---

## Key Technical Details

### Firebase Configuration
- **Database URL**: `https://airplane-battle-7a3fd-default-rtdb.firebaseio.com`
- **Realtime DB path**: `activeGames/{gameId}`
- **Firestore collections**: `users`, `gameHistory`, `matchmakingQueue`, `roomCodes`

### Online Game Data Flow
```
waiting → deploying → battle → finished
```

### Field Compatibility (iOS <-> Android)
- Ready state: Writes both `playerReady` and `ready` fields
- Deployment: Writes both `deploymentReady` and `ready` + `board` data
- currentTurn: Uses **userId** (not "player1"/"player2" role)
- Attacks: Stored under `{role}/attacks/{pushKey}` with result field
- Stats: Stored under `{role}/stats` with hits/misses/kills

### Device Info

| 设备名 | 型号 | Device ID | 安装状态 |
|--------|------|-----------|----------|
| sisi | iPhone 12 Pro Max | `00008101-000600E601A1001E` | 已安装 (2026-02-07) |
| wang的iPhone | iPhone 15 Plus | `00008120-000E10AA0A01A01E` | 已安装 (2026-02-07) |
| 𝓑𝓪𝓸𝓫𝓪𝓸𝓽𝓪 | iPhone XS Max | `00008020-001635D614C2002E` | 待安装 (设备离线) |

- Min iOS version: 16.0
- Build target: arm64
- Signing: Automatic (Team: 8J6A847P66, Apple Development: Sisi Wang)
- 支持 Wi-Fi 无线安装（设备需在同一网络且已配对）

### Build & Install Commands
```bash
# 构建（自动注册新设备）
xcodebuild -project HeadshotAirBattle.xcodeproj -scheme HeadshotAirBattle \
  -destination 'platform=iOS,id=<DEVICE_UDID>' \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration build

# 无线安装到指定设备
xcrun devicectl device install app --device <DEVICE_UDID> \
  /Users/wangsisi/Library/Developer/Xcode/DerivedData/HeadshotAirBattle-fihvvnxrsthoknccbeewdozoygpc/Build/Products/Debug-iphoneos/HeadshotAirBattle.app

# 查看已连接设备
xcrun devicectl list devices
```

---

## Recent Changes

### 2026-02-07 (Device Installation)
1. **注册 iPhone 15 Plus 到开发者账号** - 使用 `-allowProvisioningDeviceRegistration` 自动注册新设备
2. **无线安装到 iPhone 15 Plus** - 通过 Wi-Fi 使用 `xcrun devicectl` 安装成功
3. **无线安装到 iPhone 12 Pro Max (sisi)** - 通过 Wi-Fi 安装成功
4. **iPhone XS Max (𝓑𝓪𝓸𝓫𝓪𝓸𝓽𝓪) 待安装** - 设备离线，下次更新时一并安装

### 2026-02-07 (Final Update)
1. **Added online game achievements** - Achievement system now triggers for online games (first win, sharpshooter, prophet, etc.)
2. **Confirmed cross-platform compatibility** - Quick Match tested and working between iOS-iOS and iOS-Android

### 2026-02-07 (Evening Update)
1. **Fixed deployment drag offset** - Airplane preview now accurately follows finger position during drag
2. **Added landscape orientation support** - Both AI and online battles now display boards side-by-side in landscape mode
3. **Enhanced battle report** - Added game duration estimation, player efficiency, and winner-highlighted player cards (matching Android version)

### 2026-02-07 (Morning Update)
1. **Fixed online battle airplane display** - Player's deployed airplanes now show consistent detailed shapes in battle view
2. **Fixed Data Analyst achievement** - Achievement now unlocks when viewing battle reports
3. **Improved skin/theme unlock display** - Shows detailed progress like "Need 3 more games" instead of generic text
4. **Added surrender to AI battles** - All AI game modes now have surrender button
5. **Optimized large board performance** - Improved rendering performance for 15x15 and 20x20 boards
6. **Hidden debug panels** - DEBUG info now only visible in debug builds, not production

### 2026-02-06

1. **Fixed online Ready flow** - Both players must click Ready before deployment
2. **Fixed currentTurn** - Uses userId instead of role (matches Android)
3. **Created OnlineBattleView** - Proper online battle view with attack tracking
4. **Fixed attack system** - Calculates hit/miss/kill locally, sends result to Firebase
5. **Added attack visualization** - Shows hit (flame), miss (dot), kill (X) on boards
6. **Fixed Quick Match** - Creates game in Realtime DB, both players go to RoomLobby
7. **Fixed RoomLobby navigation** - Only navigates when both Ready AND status=deploying
8. **Added game history recording** - Online games saved to Firestore + local
9. **Added statistics update** - Online wins/losses tracked in leaderboard
10. **Added haptic feedback** - miss(light), hit(medium), kill(pattern) vibrations
11. **Added audio SFX calls** - playSFX for hit/miss/kill in online attacks
12. **Added BGM** - Starts on battle, stops on finish
13. **Added surrender** - With confirmation and proper stat recording
