import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct HeadshotAirBattleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Only initialize AdMob if a real app ID is configured
                    if let adId = Bundle.main.infoDictionary?["GADApplicationIdentifier"] as? String,
                       !adId.contains("XXXXXXXXXX") {
                        AdService.shared.initialize()
                    } else {
                        print("[AdService] Skipped initialization: no valid GADApplicationIdentifier configured")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if AdService.shared.isInitialized {
                        AdService.shared.requestTrackingPermission()
                    }
                }
        }
    }
}
