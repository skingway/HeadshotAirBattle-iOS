import SwiftUI
import GoogleMobileAds

/// SwiftUI wrapper for GADBannerView
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        bannerView.adUnitID = adUnitID
        bannerView.backgroundColor = .clear

        // Find root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootVC
        }

        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

/// Conditionally shows banner ad (hidden when ads removed via IAP)
struct ConditionalBannerAd: View {
    @ObservedObject private var adService = AdService.shared

    var body: some View {
        if adService.shouldShowBannerAd() {
            BannerAdView(adUnitID: AdConfig.bannerAdUnitId)
                .frame(height: 50)
        }
    }
}
