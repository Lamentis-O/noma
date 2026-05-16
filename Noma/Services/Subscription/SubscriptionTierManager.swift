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

    var taskLimitPerGroup: Int? {
        switch self {
        case .free:
            5
        case .pro:
            nil
        }
    }

    func canAddTask(toGroupWithTaskCount taskCount: Int) -> Bool {
        guard let taskLimitPerGroup else { return true }
        return taskCount < taskLimitPerGroup
    }
}

@MainActor
@Observable
final class SubscriptionTierManager {
    private(set) var tier: SubscriptionTier = .free

    var isPro: Bool { tier == .pro }

    func updateTier(_ tier: SubscriptionTier) {
        self.tier = tier
    }

    func debugUnlockPro() {
        updateTier(.pro)
    }
}
