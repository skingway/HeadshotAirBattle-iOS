import Foundation

/// AdMob configuration matching Android counterparts
enum AdConfig {
    // TODO: Replace with actual iOS ad unit IDs from AdMob console
    // Using same publisher ID as Android: ca-app-pub-3709728062444091

    #if DEBUG
    // Test ad unit IDs for development
    static let bannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"
    static let interstitialAdUnitId = "ca-app-pub-3940256099942544/4411468910"
    #else
    // Production ad unit IDs (create these in AdMob console for iOS)
    static let bannerAdUnitId = "ca-app-pub-3709728062444091/XXXXXXXXXX"
    static let interstitialAdUnitId = "ca-app-pub-3709728062444091/YYYYYYYYYY"
    #endif

    /// Show interstitial every N games
    static let interstitialEveryNGames = 3

    /// Minimum seconds between interstitials
    static let minInterstitialIntervalSeconds: TimeInterval = 60
}
