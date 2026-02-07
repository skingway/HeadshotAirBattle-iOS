import GoogleMobileAds
import AppTrackingTransparency
import Foundation

/// Manages AdMob banner and interstitial ads
@MainActor
class AdService: ObservableObject {
    static let shared = AdService()

    @Published var isBannerReady = false
    @Published var isInitialized = false

    private var interstitialAd: GADInterstitialAd?
    private var gamesPlayedSinceAd: Int
    private var lastInterstitialTime: TimeInterval

    private init() {
        gamesPlayedSinceAd = UserDefaults.standard.integer(forKey: GameConstants.StorageKeys.gamesPlayedSinceAd)
        lastInterstitialTime = UserDefaults.standard.double(forKey: GameConstants.StorageKeys.lastInterstitialTime)
    }

    // MARK: - Initialization

    func initialize() {
        guard !isInitialized else { return }

        GADMobileAds.sharedInstance().start { [weak self] status in
            print("[AdService] AdMob initialized: \(status.adapterStatusesByClassName)")
            Task { @MainActor in
                self?.isInitialized = true
                self?.loadInterstitialAd()
            }
        }
    }

    /// Request App Tracking Transparency permission (must be called after app becomes active)
    func requestTrackingPermission() {
        guard #available(iOS 14, *) else { return }
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("[AdService] Tracking authorized")
            case .denied:
                print("[AdService] Tracking denied")
            case .restricted:
                print("[AdService] Tracking restricted")
            case .notDetermined:
                print("[AdService] Tracking not determined")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Banner Ads

    func shouldShowBannerAd() -> Bool {
        return isInitialized && !IAPService.shared.isAdsRemoved()
    }

    // MARK: - Interstitial Ads

    func loadInterstitialAd() {
        guard !IAPService.shared.isAdsRemoved() else { return }

        GADInterstitialAd.load(withAdUnitID: AdConfig.interstitialAdUnitId,
                               request: GADRequest()) { [weak self] ad, error in
            if let error = error {
                print("[AdService] Interstitial load failed: \(error.localizedDescription)")
                return
            }
            Task { @MainActor in
                self?.interstitialAd = ad
                print("[AdService] Interstitial loaded")
            }
        }
    }

    /// Call this when a game finishes. Shows interstitial if conditions are met.
    func onGameFinished() {
        guard !IAPService.shared.isAdsRemoved() else { return }

        gamesPlayedSinceAd += 1
        UserDefaults.standard.set(gamesPlayedSinceAd, forKey: GameConstants.StorageKeys.gamesPlayedSinceAd)

        // Check frequency: every N games
        guard gamesPlayedSinceAd >= AdConfig.interstitialEveryNGames else { return }

        // Check time interval
        let now = Date().timeIntervalSince1970
        guard now - lastInterstitialTime >= AdConfig.minInterstitialIntervalSeconds else { return }

        showInterstitial()
    }

    private func showInterstitial() {
        guard let ad = interstitialAd else {
            print("[AdService] No interstitial available")
            loadInterstitialAd()
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // Find the topmost presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        ad.present(fromRootViewController: topVC)
        print("[AdService] Interstitial shown")

        // Reset counters
        gamesPlayedSinceAd = 0
        lastInterstitialTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(0, forKey: GameConstants.StorageKeys.gamesPlayedSinceAd)
        UserDefaults.standard.set(lastInterstitialTime, forKey: GameConstants.StorageKeys.lastInterstitialTime)

        // Pre-load next interstitial
        interstitialAd = nil
        loadInterstitialAd()
    }
}
