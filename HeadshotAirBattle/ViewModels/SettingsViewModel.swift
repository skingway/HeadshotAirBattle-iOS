import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var audioEnabled: Bool {
        didSet { UserDefaults.standard.set(audioEnabled, forKey: GameConstants.StorageKeys.audioEnabled) }
    }
    @Published var bgmVolume: Float {
        didSet { UserDefaults.standard.set(bgmVolume, forKey: GameConstants.StorageKeys.bgmVolume) }
    }
    @Published var sfxVolume: Float {
        didSet { UserDefaults.standard.set(sfxVolume, forKey: GameConstants.StorageKeys.sfxVolume) }
    }
    @Published var showSignOutConfirm = false
    @Published var showDeleteConfirm = false

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: GameConstants.StorageKeys.audioEnabled) == nil {
            self.audioEnabled = GameConstants.Audio.enabledByDefault
        } else {
            self.audioEnabled = defaults.bool(forKey: GameConstants.StorageKeys.audioEnabled)
        }

        let storedBgm = defaults.float(forKey: GameConstants.StorageKeys.bgmVolume)
        self.bgmVolume = storedBgm > 0 ? storedBgm : GameConstants.Audio.bgmVolume

        let storedSfx = defaults.float(forKey: GameConstants.StorageKeys.sfxVolume)
        self.sfxVolume = storedSfx > 0 ? storedSfx : GameConstants.Audio.sfxVolume
    }
}
