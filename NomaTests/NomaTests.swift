//
//  NomaTests.swift
//  NomaTests
//
//  Created by Elias Papavlassopoulos on 15.05.26.
//

@testable import Noma
import XCTest

final class NomaTests: XCTestCase {
    func testSpacingContractExposesXsToken() {
        XCTAssertEqual(NomaSpacing.xs, 4)
    }

    func testCreateViewDoesNotFocusInputWhenInitialDelayIsCancelled() async {
        let shouldFocus = await CreateView.shouldApplyInitialFocus {
            throw CancellationError()
        }

        XCTAssertFalse(shouldFocus)
    }

    func testCreateViewFocusesInputAfterInitialDelayCompletes() async {
        let shouldFocus = await CreateView.shouldApplyInitialFocus {}

        XCTAssertTrue(shouldFocus)
    }

    func testProjectEmptyStateOmitsCTAUntilProjectCreationFlowExists() {
        XCTAssertNil(CreateProjectEmptyState.placeholder.cta)
    }

    func testSupabaseConfigurationTargetsNomaProject() {
        XCTAssertEqual(
            SupabaseClientProvider.projectURL.absoluteString,
            "https://ejulpxdohfnojevqntks.supabase.co"
        )
    }

    func testSupabaseConfigurationRequiresPublishableKey() {
        let configuration = SupabaseConfiguration(
            projectURL: SupabaseClientProvider.projectURL,
            publishableKey: ""
        )

        XCTAssertFalse(configuration.isConfigured)
    }

    func testSupabaseCurrentConfigurationIncludesPublishableKey() {
        XCTAssertTrue(SupabaseClientProvider.currentConfiguration.isConfigured)
        XCTAssertEqual(
            SupabaseClientProvider.currentConfiguration.publishableKey,
            SupabaseClientProvider.bundledPublishableKey
        )
    }

    func testAuthSessionSnapshotMapsToRootPhases() {
        XCTAssertEqual(AuthSessionSnapshot(isSignedIn: false).rootPhase, .signedOut)
        XCTAssertEqual(AuthSessionSnapshot(isSignedIn: true).rootPhase, .signedIn)
    }

    func testSignupLayoutUsesRequestedSpacing() {
        XCTAssertEqual(SignInWithAppleGlassButtonLayout.verticalPadding, 12)
        XCTAssertEqual(SignupViewLayout.edgePadding, 32)
        XCTAssertEqual(SignupViewLayout.bottomPadding, 32)
    }

    func testSignInWithAppleLoadingStateUsesSpinnerAndBlocksRepeatedTaps() {
        XCTAssertTrue(SignInWithAppleGlassButtonState(isLoading: true).showsProgressSpinner)
        XCTAssertFalse(SignInWithAppleGlassButtonState(isLoading: true).allowsInteraction)
        XCTAssertTrue(SignInWithAppleGlassButtonState(isLoading: true).usesBlurReplaceTransition)
        XCTAssertTrue(SignInWithAppleGlassButtonState(isLoading: true).preservesLabelLayout)
    }

    func testFeatureAccessSeparatesFreeAndProEntitlements() {
        XCTAssertTrue(FeatureAccessPolicy.canUse(.createTask, entitlement: .free))
        XCTAssertFalse(FeatureAccessPolicy.canUse(.unlimitedTasks, entitlement: .free))
        XCTAssertTrue(FeatureAccessPolicy.canUse(.unlimitedTasks, entitlement: .activePro))
    }

    @MainActor
    func testSubscriptionStateLoadsFreeEntitlementFromBackend() async {
        let subscriptionState = SubscriptionStateManager(
            entitlementClient: StubEntitlementClient(entitlements: [.free]),
            storeKitClient: StubStoreKitClient()
        )

        await subscriptionState.refreshEntitlement()

        XCTAssertEqual(subscriptionState.phase, .free(.free))
    }

    @MainActor
    func testSubscriptionPurchaseRefreshesEntitlementToPro() async {
        let subscriptionState = SubscriptionStateManager(
            entitlementClient: StubEntitlementClient(entitlements: [.free, .activePro]),
            storeKitClient: StubStoreKitClient(products: [.monthlyPro])
        )

        await subscriptionState.refreshEntitlement()
        await subscriptionState.purchase(.monthlyPro)

        XCTAssertEqual(subscriptionState.phase, .pro(.activePro))
        XCTAssertFalse(subscriptionState.isPurchasing)
    }

    @MainActor
    func testSignInWithAppleAppliesReturnedSessionSnapshotImmediately() async {
        let authState = AuthStateManager(
            authClient: SignInSucceedsAuthClient(),
            appleSignInProvider: StubAppleSignInProvider()
        )
        authState.phase = .signedOut

        await authState.signInWithAppleFlow()

        XCTAssertEqual(authState.phase, .signedIn)
        XCTAssertFalse(authState.isSigningIn)
    }

    @MainActor
    func testSignInWithAppleReportsFailureAndClearsLoading() async {
        let authState = AuthStateManager(
            authClient: SignInFailsAuthClient(),
            appleSignInProvider: StubAppleSignInProvider()
        )
        authState.phase = .signedOut

        await authState.signInWithAppleFlow()

        XCTAssertEqual(authState.phase, .signedOut)
        XCTAssertEqual(authState.errorMessage, TestAuthError.signInRejected.localizedDescription)
        XCTAssertFalse(authState.isSigningIn)
    }

    @MainActor
    func testSignOutAppliesSignedOutSnapshot() async {
        let authState = AuthStateManager(
            authClient: SignOutSucceedsAuthClient(),
            appleSignInProvider: StubAppleSignInProvider()
        )
        authState.phase = .signedIn

        await authState.signOutFlow()

        XCTAssertEqual(authState.phase, .signedOut)
        XCTAssertNil(authState.errorMessage)
    }
}

private struct StubAppleSignInProvider: AppleSignInProviding {
    func requestCredential() async throws -> AppleSignInCredential {
        AppleSignInCredential(
            identityToken: "identity-token",
            nonce: "nonce",
            fullName: nil
        )
    }
}

private struct SignInSucceedsAuthClient: AuthClient {
    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: false)
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: true)
    }

    func signOut() async throws {}
}

private struct SignInFailsAuthClient: AuthClient {
    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: false)
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        throw TestAuthError.signInRejected
    }

    func signOut() async throws {}
}

private struct SignOutSucceedsAuthClient: AuthClient {
    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: true)
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: true)
    }

    func signOut() async throws {}
}

private struct StubEntitlementClient: EntitlementClient {
    var entitlements: [UserEntitlement]

    func currentEntitlement() async throws -> UserEntitlement {
        entitlements.first ?? .free
    }

    func refreshEntitlement() async throws -> UserEntitlement {
        entitlements.dropFirst().first ?? entitlements.first ?? .free
    }

    func appAccountToken() async throws -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }
}

private struct StubStoreKitClient: StoreKitClient {
    var products: [SubscriptionProduct] = []

    func availableProducts() async throws -> [SubscriptionProduct] {
        products
    }

    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome {
        .purchased(transactionID: "test-transaction")
    }

    func restorePurchases() async throws {}
}

private enum TestAuthError: LocalizedError {
    case signInRejected

    var errorDescription: String? {
        "Sign in rejected"
    }
}
