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

    @MainActor
    func testSubscriptionTierManagerStartsInFreeTier() {
        let subscriptionTier = SubscriptionTierManager()

        XCTAssertEqual(subscriptionTier.tier, .free)
        XCTAssertFalse(subscriptionTier.isPro)
    }

    @MainActor
    func testSubscriptionTierManagerCanSwitchBetweenFreeAndPro() {
        let subscriptionTier = SubscriptionTierManager()

        subscriptionTier.updateTier(.pro)

        XCTAssertEqual(subscriptionTier.tier, .pro)
        XCTAssertTrue(subscriptionTier.isPro)

        subscriptionTier.updateTier(.free)

        XCTAssertEqual(subscriptionTier.tier, .free)
        XCTAssertFalse(subscriptionTier.isPro)
    }

    func testSubscriptionTierDisplayConfigurationMatchesTier() {
        XCTAssertEqual(SubscriptionTier.free.titleKey, "subscription.tier.free.title")
        XCTAssertFalse(SubscriptionTier.free.usesProminentTextGradient)

        XCTAssertEqual(SubscriptionTier.pro.titleKey, "subscription.tier.pro.title")
        XCTAssertTrue(SubscriptionTier.pro.usesProminentTextGradient)
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

private enum TestAuthError: LocalizedError {
    case signInRejected

    var errorDescription: String? {
        "Sign in rejected"
    }
}
