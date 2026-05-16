import Observation

enum SubscriptionTier: Equatable {
    case free
    case pro

    var titleKey: String {
        switch self {
        case .free:
            "subscription.tier.free.title"
        case .pro:
            "subscription.tier.pro.title"
        }
    }

    var usesProminentTextGradient: Bool { self == .pro }
}

@MainActor
@Observable
final class SubscriptionTierManager {
    private(set) var tier: SubscriptionTier = .free

    var isPro: Bool { tier == .pro }

    func updateTier(_ tier: SubscriptionTier) {
        self.tier = tier
    }
}
