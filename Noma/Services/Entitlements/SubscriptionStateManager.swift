import Foundation
import Observation

@MainActor
@Observable
final class SubscriptionStateManager {
    private let entitlementClient: any EntitlementClient
    private let storeKitClient: any StoreKitClient
    private var hasStarted = false

    var phase: SubscriptionPhase = .loading
    var availableProducts: [SubscriptionProduct] = []
    var errorMessage: String?
    var isPurchasing = false

    convenience init() {
        let entitlementClient = EntitlementClientProvider.makeClient()
        self.init(
            entitlementClient: entitlementClient,
            storeKitClient: StoreKit2Client {
                try await entitlementClient.appAccountToken()
            }
        )
    }

    init(
        entitlementClient: any EntitlementClient,
        storeKitClient: any StoreKitClient
    ) {
        self.entitlementClient = entitlementClient
        self.storeKitClient = storeKitClient
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    func reset() {
        hasStarted = false
        phase = .loading
        availableProducts = []
        errorMessage = nil
        isPurchasing = false
    }

    func refreshEntitlement() async {
        errorMessage = nil

        do {
            let entitlement = try await entitlementClient.refreshEntitlement()
            phase = SubscriptionPhase.resolved(from: entitlement)
        } catch {
            phase = .unavailable(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: SubscriptionProduct) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let outcome = try await storeKitClient.purchase(product)
            switch outcome {
            case .purchased:
                await refreshEntitlement()
            case .pending:
                phase = .unavailable("Purchase is pending.")
            case .cancelled:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await storeKitClient.restorePurchases()
            await refreshEntitlement()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProducts() async {
        do {
            availableProducts = try await storeKitClient.availableProducts()
        } catch {
            availableProducts = []
        }
    }
}
