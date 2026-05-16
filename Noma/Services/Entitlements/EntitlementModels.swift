import Foundation

enum SubscriptionTier: String, Codable, Equatable {
    case free
    case pro
}

enum EntitlementStatus: String, Codable, Equatable {
    case active
    case gracePeriod
    case billingRetry
    case expired
    case revoked
    case unknown
}

struct UserEntitlement: Codable, Equatable {
    let tier: SubscriptionTier
    let status: EntitlementStatus
    let productID: String?
    let originalTransactionID: String?
    let expiresAt: Date?

    var unlocksPro: Bool {
        tier == .pro && [.active, .gracePeriod, .billingRetry].contains(status)
    }

    static let free = UserEntitlement(
        tier: .free,
        status: .active,
        productID: nil,
        originalTransactionID: nil,
        expiresAt: nil
    )

    static let activePro = UserEntitlement(
        tier: .pro,
        status: .active,
        productID: SubscriptionProducts.monthlyProID,
        originalTransactionID: "test-original-transaction",
        expiresAt: nil
    )
}

enum EntitlementFeature {
    case createTask
    case unlimitedTasks
    case premiumPlanning
}

enum FeatureAccessPolicy {
    static func canUse(
        _ feature: EntitlementFeature,
        entitlement: UserEntitlement
    ) -> Bool {
        switch feature {
        case .createTask:
            true
        case .unlimitedTasks, .premiumPlanning:
            entitlement.unlocksPro
        }
    }
}

enum SubscriptionPhase: Equatable {
    case loading
    case free(UserEntitlement)
    case pro(UserEntitlement)
    case expired(UserEntitlement)
    case unavailable(String?)

    static func resolved(from entitlement: UserEntitlement) -> SubscriptionPhase {
        guard entitlement.tier == .pro else { return .free(entitlement) }
        return entitlement.unlocksPro ? .pro(entitlement) : .expired(entitlement)
    }
}
