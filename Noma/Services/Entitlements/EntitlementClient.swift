import Foundation
import Supabase

@MainActor
protocol EntitlementClient {
    func currentEntitlement() async throws -> UserEntitlement
    func refreshEntitlement() async throws -> UserEntitlement
    func appAccountToken() async throws -> UUID
    func syncStoreKitTransaction(_ transaction: StoreKitTransactionSnapshot) async throws -> UserEntitlement
}

struct SupabaseEntitlementClient: EntitlementClient {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func currentEntitlement() async throws -> UserEntitlement {
        try await loadEntitlement()
    }

    func refreshEntitlement() async throws -> UserEntitlement {
        try await loadEntitlement()
    }

    func appAccountToken() async throws -> UUID {
        try await loadRow().appAccountToken
    }

    func syncStoreKitTransaction(_ transaction: StoreKitTransactionSnapshot) async throws -> UserEntitlement {
        let row: EntitlementRow = try await client.functions.invoke(
            "sync-apple-transaction",
            options: .init(method: .post, body: SyncStoreKitTransactionRequest(transaction: transaction))
        )

        return row.entitlement
    }

    private func loadEntitlement() async throws -> UserEntitlement {
        try await loadRow().entitlement
    }

    private func loadRow() async throws -> EntitlementRow {
        try await client
            .from("user_entitlements")
            .select()
            .single()
            .execute()
            .value
    }
}

struct StaticFreeEntitlementClient: EntitlementClient {
    func currentEntitlement() async throws -> UserEntitlement {
        .free
    }

    func refreshEntitlement() async throws -> UserEntitlement {
        .free
    }

    func appAccountToken() async throws -> UUID {
        UUID()
    }

    func syncStoreKitTransaction(_ transaction: StoreKitTransactionSnapshot) async throws -> UserEntitlement {
        .free
    }
}

private struct SyncStoreKitTransactionRequest: Encodable {
    let transactionID: String
    let originalTransactionID: String
    let productID: String
    let transactionJSONRepresentation: String
    let appAccountToken: UUID?

    init(transaction: StoreKitTransactionSnapshot) {
        transactionID = transaction.transactionID
        originalTransactionID = transaction.originalTransactionID
        productID = transaction.productID
        transactionJSONRepresentation = transaction.transactionJSONRepresentation
        appAccountToken = transaction.appAccountToken
    }

    private enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case originalTransactionID = "original_transaction_id"
        case productID = "product_id"
        case transactionJSONRepresentation = "transaction_json_representation"
        case appAccountToken = "app_account_token"
    }
}

enum EntitlementClientProvider {
    @MainActor
    static func makeClient() -> any EntitlementClient {
        do {
            return SupabaseEntitlementClient(client: try SupabaseClientProvider.makeClient())
        } catch {
            return StaticFreeEntitlementClient()
        }
    }
}

private struct EntitlementRow: Decodable {
    let tier: SubscriptionTier
    let status: DatabaseEntitlementStatus
    let productID: String?
    let originalTransactionID: String?
    let expiresAt: Date?
    let appAccountToken: UUID

    var entitlement: UserEntitlement {
        UserEntitlement(
            tier: tier,
            status: status.appStatus,
            productID: productID,
            originalTransactionID: originalTransactionID,
            expiresAt: expiresAt
        )
    }

    private enum CodingKeys: String, CodingKey {
        case tier
        case status
        case productID = "product_id"
        case originalTransactionID = "original_transaction_id"
        case expiresAt = "expires_at"
        case appAccountToken = "app_account_token"
    }
}

private enum DatabaseEntitlementStatus: String, Decodable {
    case active
    case gracePeriod = "grace_period"
    case billingRetry = "billing_retry"
    case expired
    case revoked

    var appStatus: EntitlementStatus {
        switch self {
        case .active:
            .active
        case .gracePeriod:
            .gracePeriod
        case .billingRetry:
            .billingRetry
        case .expired:
            .expired
        case .revoked:
            .revoked
        }
    }
}
