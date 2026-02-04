import AVFoundation
import UIKit

/// Audio service managing sound effects, background music, and vibration
class AudioService {
    static let shared = AudioService()

    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?
    private var isEnabled: Bool
    private var bgmVolume: Float
    private var sfxVolume: Float

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: GameConstants.StorageKeys.audioEnabled) != nil {
            self.isEnabled = defaults.bool(forKey: GameConstants.StorageKeys.audioEnabled)
        } else {
            self.isEnabled = GameConstants.Audio.enabledByDefault
        }

        let storedBgm = defaults.float(forKey: GameConstants.StorageKeys.bgmVolume)
        self.bgmVolume = storedBgm > 0 ? storedBgm : GameConstants.Audio.bgmVolume

        let storedSfx = defaults.float(forKey: GameConstants.StorageKeys.sfxVolume)
        self.sfxVolume = storedSfx > 0 ? storedSfx : GameConstants.Audio.sfxVolume

        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        preloadSounds()
    }

    // MARK: - Preload

    private func preloadSounds() {
        let soundNames = ["miss", "hit", "kill", "victory", "defeat"]
        for name in soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                sfxPlayers[name] = try? AVAudioPlayer(contentsOf: url)
                sfxPlayers[name]?.prepareToPlay()
            }
        }
    }

    // MARK: - SFX

    func playSFX(for result: GameConstants.AttackResult) {
        let soundName: String
        switch result {
        case .miss: soundName = "miss"
        case .hit: soundName = "hit"
        case .kill: soundName = "kill"
        default: return
        }
        playSFX(named: soundName)
        playVibration(for: result)
    }

    func playSFX(named name: String) {
        guard isEnabled else { return }

        if let player = sfxPlayers[name] {
            player.volume = sfxVolume
            player.currentTime = 0
            player.play()
        }
    }

    func playVictory() {
        playSFX(named: "victory")
        playVibrationPattern([0, 50, 50, 50, 50, 100])
    }

    func playDefeat() {
        playSFX(named: "defeat")
        playVibrationPattern([0, 200, 100, 200])
    }

    // MARK: - Vibration

    private func playVibration(for result: GameConstants.AttackResult) {
        switch result {
        case .miss:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .hit:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .kill:
            playVibrationPattern([0, 100, 50, 100])
        default:
            break
        }
    }

    private func playVibrationPattern(_ pattern: [Int]) {
        // UIKit vibration patterns via AudioServicesPlaySystemSound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // For more complex patterns, chain haptics
        for (index, duration) in pattern.enumerated() where duration > 0 && index % 2 == 1 {
            let delay = pattern[0..<index].reduce(0, +)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) / 1000) {
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
            }
        }
    }

    // MARK: - BGM

    func playBGM() {
        guard isEnabled else { return }

        if bgmPlayer == nil {
            if let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
                bgmPlayer = try? AVAudioPlayer(contentsOf: url)
                bgmPlayer?.numberOfLoops = -1 // Loop indefinitely
            }
        }

        bgmPlayer?.volume = bgmVolume
        bgmPlayer?.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer?.currentTime = 0
    }

    func pauseBGM() {
        bgmPlayer?.pause()
    }

    // MARK: - Settings

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: GameConstants.StorageKeys.audioEnabled)
        if !enabled {
            stopBGM()
        }
    }

    func setBGMVolume(_ volume: Float) {
        bgmVolume = volume
        bgmPlayer?.volume = volume
        UserDefaults.standard.set(volume, forKey: GameConstants.StorageKeys.bgmVolume)
    }

    func setSFXVolume(_ volume: Float) {
        sfxVolume = volume
        UserDefaults.standard.set(volume, forKey: GameConstants.StorageKeys.sfxVolume)
    }

    func getSettings() -> (enabled: Bool, bgmVolume: Float, sfxVolume: Float) {
        return (isEnabled, bgmVolume, sfxVolume)
    }

    func release() {
        stopBGM()
        bgmPlayer = nil
        sfxPlayers.values.forEach { $0.stop() }
        sfxPlayers.removeAll()
    }
}
