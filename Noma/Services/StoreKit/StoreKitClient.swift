import Foundation
import StoreKit

struct SubscriptionProduct: Identifiable, Equatable {
    let id: String
    let displayName: String
    let displayPrice: String
    let tier: SubscriptionTier

    static let monthlyPro = SubscriptionProduct(
        id: SubscriptionProducts.monthlyProID,
        displayName: "Noma Pro Monthly",
        displayPrice: "$4.99",
        tier: .pro
    )
}

enum SubscriptionProducts {
    static let monthlyProID = "noma.pro.monthly"
    static let yearlyProID = "noma.pro.yearly"
    static let configuredIDs = [monthlyProID, yearlyProID]
}

struct StoreKitTransactionSnapshot: Codable, Equatable {
    let transactionID: String
    let originalTransactionID: String
    let productID: String
    let transactionJSONRepresentation: String
    let appAccountToken: UUID?
    let expiresAt: Date?
}

enum PurchaseOutcome: Equatable {
    case purchased(StoreKitTransactionSnapshot)
    case pending
    case cancelled
}

@MainActor
protocol StoreKitClient {
    func availableProducts() async throws -> [SubscriptionProduct]
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome
    func restorePurchases() async throws
    func currentEntitlementTransactions() async throws -> [StoreKitTransactionSnapshot]
}

struct StoreKit2Client: StoreKitClient {
    private let productIDs: [String]
    private let appAccountTokenProvider: (() async throws -> UUID)?

    init(
        productIDs: [String] = SubscriptionProducts.configuredIDs,
        appAccountTokenProvider: (() async throws -> UUID)? = nil
    ) {
        self.productIDs = productIDs
        self.appAccountTokenProvider = appAccountTokenProvider
    }

    func availableProducts() async throws -> [SubscriptionProduct] {
        let products = try await Product.products(for: productIDs)
        return products.map { product in
            SubscriptionProduct(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                tier: .pro
            )
        }
    }

    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome {
        let storeProducts = try await Product.products(for: [product.id])
        guard let storeProduct = storeProducts.first else {
            throw StoreKitClientError.productUnavailable
        }

        let result: Product.PurchaseResult
        if let token = try await appAccountTokenProvider?() {
            result = try await storeProduct.purchase(options: [.appAccountToken(token)])
        } else {
            result = try await storeProduct.purchase()
        }

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let snapshot = StoreKitTransactionSnapshot(transaction: transaction)
            await transaction.finish()
            return .purchased(snapshot)
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func currentEntitlementTransactions() async throws -> [StoreKitTransactionSnapshot] {
        var snapshots: [StoreKitTransactionSnapshot] = []

        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            guard productIDs.contains(transaction.productID) else { continue }
            snapshots.append(StoreKitTransactionSnapshot(transaction: transaction))
        }

        return snapshots
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            signedType
        case .unverified:
            throw StoreKitClientError.failedVerification
        }
    }
}

private extension StoreKitTransactionSnapshot {
    init(transaction: Transaction) {
        self.init(
            transactionID: String(transaction.id),
            originalTransactionID: String(transaction.originalID),
            productID: transaction.productID,
            transactionJSONRepresentation: String(data: transaction.jsonRepresentation, encoding: .utf8) ?? "{}",
            appAccountToken: transaction.appAccountToken,
            expiresAt: transaction.expirationDate
        )
    }
}

enum StoreKitClientError: LocalizedError {
    case productUnavailable
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            "Subscription product is unavailable."
        case .failedVerification:
            "StoreKit transaction verification failed."
        }
    }
}
