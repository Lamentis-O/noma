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

    func testCreateReminderSubmissionTrimsSubmittedText() {
        let reminder = CreateReminderSubmission.reminder(from: "  Call Mika  ")

        XCTAssertEqual(reminder?.text, "Call Mika")
    }

    func testCreateReminderSubmissionRemovesWhitespaceOnlyLines() {
        let reminder = CreateReminderSubmission.reminder(from: "  Call Mika  \n   \n\n  Bring notes  \n  ")

        XCTAssertEqual(reminder?.text, "Call Mika\nBring notes")
    }

    func testCreateReminderSubmissionRejectsTextOverCharacterLimit() {
        let overLimitText = String(repeating: "a", count: CreateReminderSubmission.characterLimit + 1)

        XCTAssertNil(CreateReminderSubmission.reminder(from: overLimitText))
    }

    func testReminderInputStateDisablesAndMarksOverLimitText() {
        let state = ReminderInputState(text: String(repeating: "a", count: CreateReminderSubmission.characterLimit + 1))

        XCTAssertFalse(state.canSubmit)
        XCTAssertTrue(state.isOverLimit)
        XCTAssertEqual(state.sendButtonTone, .error)
    }

    func testCreateReminderSubmissionRejectsEmptyText() {
        XCTAssertNil(CreateReminderSubmission.reminder(from: "   \n  "))
    }

    func testCreateReminderSubmissionClearsInputAfterSuccessfulSubmit() {
        let result = CreateReminderSubmission.submit(
            text: "  Call Mika  ",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        )

        XCTAssertEqual(result?.reminder.text, "Call Mika")
        XCTAssertEqual(result?.remainingText, "")
    }

    func testCreateReminderListLayoutLeavesScrollRoomAboveComposer() {
        XCTAssertEqual(
            CreateReminderListLayout.bottomScrollPadding,
            ReminderInputBarLayout.minimumHeight + NomaSpacing.xl
        )
    }

    func testSectionHeaderLayoutUsesTwentyFourPointBottomPadding() {
        XCTAssertEqual(SectionHeaderLayout.bottomPadding, 24)
    }

    func testSectionHeaderTextFormattingUsesTitleCase() {
        XCTAssertEqual(
            SectionHeaderTextFormatting.titleCased("tasks in this group"),
            "Tasks In This Group"
        )
    }

    func testCreateReminderStartsIncompleteAndCanToggleCompletion() {
        let reminder = CreateReminder(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, text: "Call Mika")

        XCTAssertFalse(reminder.isCompleted)
        XCTAssertTrue(reminder.togglingCompletion().isCompleted)
        XCTAssertFalse(reminder.togglingCompletion().togglingCompletion().isCompleted)
    }

    func testRadioCheckboxStateOnlyShowsInnerCircleWhenOn() {
        XCTAssertFalse(RadioCheckboxState(isOn: false).showsInnerCircle)
        XCTAssertTrue(RadioCheckboxState(isOn: true).showsInnerCircle)
    }

    @MainActor
    func testSectionHeaderConfigurationUsesHeadlinePrimaryAndLeadingDefaults() {
        let configuration = SectionHeaderConfiguration(text: "Today")

        XCTAssertEqual(configuration.text, "Today")
        XCTAssertEqual(configuration.textStyle, .headline)
        XCTAssertEqual(configuration.colorSource, .primary)
        XCTAssertEqual(configuration.alignment, .leading)
    }

    @MainActor
    func testSectionHeaderConfigurationMarksCustomColorOverrides() {
        let configuration = SectionHeaderConfiguration(text: "Today", colorSource: .custom)

        XCTAssertEqual(configuration.colorSource, .custom)
    }

    func testCreateReminderListSectionUsesLocalizedTaskHeaderForEnteredTasks() {
        XCTAssertEqual(CreateReminderListSection.headerTitleKey, "create.tasks.section-header")
        XCTAssertFalse(CreateReminderListSection.showsHeader(reminderCount: 0))
        XCTAssertTrue(CreateReminderListSection.showsHeader(reminderCount: 1))
    }

    func testReminderCompletionHapticOnlyPlaysWhenToggledOn() {
        XCTAssertEqual(CreateReminderCompletionFeedback.feedback(isCompleted: true), .createTaskSubmit)
        XCTAssertNil(CreateReminderCompletionFeedback.feedback(isCompleted: false))
    }

    func testHapticFeedbackServiceRoutesSubmitFeedback() {
        var playedFeedback: [HapticFeedbackClass] = []
        let haptics = HapticFeedbackService { feedback in
            playedFeedback.append(feedback)
        }

        haptics.play(.createTaskSubmit)

        XCTAssertEqual(playedFeedback, [.createTaskSubmit])
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

    func testSupabaseClientOptionsOptIntoLocalInitialSessionEmission() {
        XCTAssertTrue(SupabaseClientProvider.emitsLocalSessionAsInitialSession)
    }

    @MainActor
    func testAuthSessionSnapshotMapsToRootPhases() {
        XCTAssertEqual(AuthSessionSnapshot(isSignedIn: false).rootPhase, .signedOut)
        XCTAssertEqual(AuthSessionSnapshot(isSignedIn: true).rootPhase, .signedIn)
        XCTAssertEqual(AuthSessionSnapshot(state: .refreshingExpiredLocalSession).rootPhase, .loading)
    }

    @MainActor
    func testAuthStateManagerKeepsExpiredStoredSessionLoadingAtStartup() async {
        let authState = AuthStateManager(
            authClient: StartupAuthClient(
                initialSnapshot: AuthSessionSnapshot(state: .refreshingExpiredLocalSession),
                streamSnapshots: []
            ),
            appleSignInProvider: StubAppleSignInProvider()
        )
        authState.phase = .signedOut

        authState.start()
        await allowAuthObserverToRun()

        XCTAssertEqual(authState.phase, .loading)
    }

    @MainActor
    func testAuthStateManagerAppliesRefreshAfterExpiredStoredSession() async {
        let authState = AuthStateManager(
            authClient: StartupAuthClient(
                initialSnapshot: AuthSessionSnapshot(state: .refreshingExpiredLocalSession),
                streamSnapshots: [AuthSessionSnapshot(state: .authenticated)]
            ),
            appleSignInProvider: StubAppleSignInProvider()
        )

        authState.start()
        await allowAuthObserverToRun()

        XCTAssertEqual(authState.phase, .signedIn)
    }

    @MainActor
    func testSubscriptionTierManagerStartsInFreeTier() async {
        let subscriptionTier = SubscriptionTierManager()

        XCTAssertEqual(subscriptionTier.tier, .free)
        XCTAssertFalse(subscriptionTier.isPro)
    }

    @MainActor
    func testSubscriptionTierManagerCanSwitchBetweenFreeAndPro() async {
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

private func allowAuthObserverToRun() async {
    await Task.yield()
    try? await Task.sleep(nanoseconds: 1_000_000)
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

private struct StartupAuthClient: AuthClient {
    let initialSnapshot: AuthSessionSnapshot
    let streamSnapshots: [AuthSessionSnapshot]

    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        initialSnapshot
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            for snapshot in streamSnapshots {
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        AuthSessionSnapshot(state: .authenticated)
    }

    func signOut() async throws {}
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
