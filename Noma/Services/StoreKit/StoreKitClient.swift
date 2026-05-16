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

enum PurchaseOutcome: Equatable {
    case purchased(transactionID: String)
    case pending
    case cancelled
}

@MainActor
protocol StoreKitClient {
    func availableProducts() async throws -> [SubscriptionProduct]
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome
    func restorePurchases() async throws
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
            await transaction.finish()
            return .purchased(transactionID: String(transaction.id))
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

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            signedType
        case .unverified:
            throw StoreKitClientError.failedVerification
        }
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
