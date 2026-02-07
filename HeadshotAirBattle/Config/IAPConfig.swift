import Foundation

/// In-App Purchase product definitions matching Android counterparts
enum IAPProduct: String, CaseIterable {
    case removeAds = "remove_ads"
    case premiumSkinPack = "premium_skin_pack"
    case premiumThemePack = "premium_theme_pack"
    case acePilotBundle = "ace_pilot_bundle"
    case nicknameFreedom = "nickname_freedom"

    var displayName: String {
        switch self {
        case .removeAds: return "Remove Ads"
        case .premiumSkinPack: return "Premium Skin Pack"
        case .premiumThemePack: return "Premium Theme Pack"
        case .acePilotBundle: return "Ace Pilot Bundle"
        case .nicknameFreedom: return "Nickname Freedom"
        }
    }

    var description: String {
        switch self {
        case .removeAds: return "Permanently remove all banner and interstitial ads"
        case .premiumSkinPack: return "4 exclusive skins: Diamond, Stealth, Flame, Aurora + unlock all earnable skins"
        case .premiumThemePack: return "3 exclusive themes: Neon City, Cherry Blossom, Midnight Gold + unlock all earnable themes"
        case .acePilotBundle: return "Everything above + Nickname Freedom. Best value, save 37%!"
        case .nicknameFreedom: return "Remove the 30-day nickname change cooldown"
        }
    }

    var icon: String {
        switch self {
        case .removeAds: return "nosign"
        case .premiumSkinPack: return "paintpalette.fill"
        case .premiumThemePack: return "sparkles"
        case .acePilotBundle: return "star.circle.fill"
        case .nicknameFreedom: return "pencil.circle.fill"
        }
    }

    /// Products included in the ace pilot bundle
    static let bundleContents: [IAPProduct] = [.removeAds, .premiumSkinPack, .premiumThemePack, .nicknameFreedom]

    /// Premium skin IDs unlocked by premiumSkinPack or acePilotBundle
    static let premiumSkinIds = ["diamond", "stealth", "flame", "aurora"]

    /// Premium theme IDs unlocked by premiumThemePack or acePilotBundle
    static let premiumThemeIds = ["neon_city", "cherry_blossom", "midnight_gold"]
}
