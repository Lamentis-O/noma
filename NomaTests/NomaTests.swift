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
        XCTAssertEqual(NomaSpacing.xl, 24)
        XCTAssertEqual(NomaSpacing.xxl, 32)
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

    func testHintViewAddsDefaultHorizontalPadding() {
        XCTAssertEqual(HintViewLayout.horizontalPadding, NomaSpacing.xl)
    }

    func testCreateTaskEmptyStateUsesHintCopyAndNoIcon() {
        let emptyState = CreateTaskEmptyState.placeholder

        XCTAssertNil(emptyState.systemImage)
        XCTAssertEqual(emptyState.titleKey, "create.tasks.empty.today.title")
        XCTAssertEqual(emptyState.subtitleKey, "create.tasks.empty.today.subtitle")
        XCTAssertFalse(emptyState.mirrorsImageForRightToLeftLayoutDirection)
        XCTAssertNil(emptyState.cta)
    }

    func testCreateReminderAutoScrollTargetsBottomAnchorAfterSubmission() {
        let reminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            text: "Last task"
        )

        XCTAssertEqual(
            CreateReminderAutoScroll.targetAfterAppending(reminder),
            CreateReminderListLayout.bottomAnchorID
        )
    }

    func testCreateReminderAutoScrollTargetsBottomAnchorAfterKeyboardFocusWithTasks() {
        XCTAssertEqual(
            CreateReminderAutoScroll.targetAfterKeyboardFocus(reminderCount: 1),
            CreateReminderListLayout.bottomAnchorID
        )
    }

    func testCreateReminderAutoScrollIgnoresKeyboardFocusWithoutTasks() {
        XCTAssertNil(CreateReminderAutoScroll.targetAfterKeyboardFocus(reminderCount: 0))
    }

    func testFreeTierLimitsTaskGroupsToFiveTasks() {
        XCTAssertEqual(SubscriptionTier.free.taskLimitPerGroup, 5)
        XCTAssertTrue(SubscriptionTier.free.canAddTask(toGroupWithTaskCount: 4))
        XCTAssertFalse(SubscriptionTier.free.canAddTask(toGroupWithTaskCount: 5))
    }

    func testProTierCanAddTasksBeyondFreeLimit() {
        XCTAssertNil(SubscriptionTier.pro.taskLimitPerGroup)
        XCTAssertTrue(SubscriptionTier.pro.canAddTask(toGroupWithTaskCount: 5))
        XCTAssertTrue(SubscriptionTier.pro.canAddTask(toGroupWithTaskCount: 50))
    }

    func testCreateReminderListShowsUnlockMoreAtFreeLimitOnly() {
        XCTAssertFalse(CreateReminderListSection.showsUnlockMoreButton(tier: .free, reminderCount: 4))
        XCTAssertTrue(CreateReminderListSection.showsUnlockMoreButton(tier: .free, reminderCount: 5))
        XCTAssertFalse(CreateReminderListSection.showsUnlockMoreButton(tier: .pro, reminderCount: 5))
    }

    @MainActor
    func testReminderInputStateDisablesSubmitWhenSubscriptionLimitIsReached() {
        let state = ReminderInputState(text: "Next task", isSubmissionAvailable: false)

        XCTAssertFalse(state.canSubmit)
        XCTAssertEqual(state.sendButtonTone, .disabled)
    }

    func testPrimaryButtonUsesSharedLayoutTokens() {
        XCTAssertEqual(PrimaryButtonLayout.horizontalPadding, NomaSpacing.xl)
        XCTAssertEqual(PrimaryButtonLayout.verticalPadding, NomaSpacing.md)
    }

    @MainActor
    func testPrimaryButtonUsesSharedSubmitHapticFeedback() {
        XCTAssertEqual(PrimaryButtonFeedback.feedback, .createTaskSubmit)
    }

    func testCreateReminderListLimitCalloutUsesProfessionalCopyAndSpacing() {
        XCTAssertEqual(
            CreateReminderListSection.unlockMoreMessageKey,
            "create.tasks.unlock-more.today.message"
        )
        XCTAssertEqual(CreateReminderLimitCalloutLayout.spacingFromTasks, 24)
        XCTAssertEqual(CreateReminderLimitCalloutLayout.contentSpacing, NomaSpacing.md)
    }

    @MainActor
    func testDebugUnlockMorePromotesAccountToPro() async {
        let subscriptionTier = SubscriptionTierManager()

        subscriptionTier.debugUnlockPro()

        XCTAssertEqual(subscriptionTier.tier, .pro)
    }

    func testCreateReminderListShowsEmptyStateOnlyWithoutTasks() {
        XCTAssertTrue(CreateReminderListSection.showsEmptyState(reminderCount: 0))
        XCTAssertFalse(CreateReminderListSection.showsEmptyState(reminderCount: 1))
    }

    func testCreateViewOnlyUsesScrollViewAfterTasksWereAdded() {
        XCTAssertFalse(CreateViewContentMode.usesScrollView(reminderCount: 0))
        XCTAssertTrue(CreateViewContentMode.usesScrollView(reminderCount: 1))
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

    @MainActor
    func testReminderInputStateDisablesAndMarksOverLimitText() {
        let state = ReminderInputState(text: String(repeating: "a", count: CreateReminderSubmission.characterLimit + 1))

        XCTAssertFalse(state.canSubmit)
        XCTAssertTrue(state.isOverLimit)
        XCTAssertEqual(state.sendButtonTone, .error)
    }

    @MainActor
    func testReminderInputStateCountsNormalizedTextForLimit() {
        let validTextWithExtraWhitespace = "\n  \(String(repeating: "a", count: CreateReminderSubmission.characterLimit))  \n"
        let state = ReminderInputState(text: validTextWithExtraWhitespace)

        XCTAssertEqual(state.normalizedText.count, CreateReminderSubmission.characterLimit)
        XCTAssertTrue(state.canSubmit)
        XCTAssertFalse(state.isOverLimit)
        XCTAssertEqual(state.sendButtonTone, .active)
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

    func testReminderInputRejectsSubmittedTextWrittenBackAfterClear() {
        var staleGuard = ReminderInputStaleTextGuard()

        staleGuard.prepareForSubmit(text: "Call Mika")

        XCTAssertFalse(staleGuard.acceptsIncomingText("Call Mika"))
        XCTAssertTrue(staleGuard.acceptsIncomingText("Next task"))
    }

    func testCreateReminderListLayoutLeavesScrollRoomAboveComposer() {
        XCTAssertEqual(
            CreateReminderListLayout.bottomScrollPadding,
            NomaSpacing.xl
        )
    }

    func testSectionHeaderLayoutUsesTwentyFourPointBottomPadding() {
        XCTAssertEqual(SectionHeaderLayout.bottomPadding, 24)
    }

    func testSectionHeaderTextFormattingUsesTitleCase() {
        XCTAssertEqual(
            SectionHeaderTextFormatting.titleCased("tasks for today"),
            "Tasks For Today"
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

    func testCreateReminderListSectionUsesLocalizedTaskHeaderForEnteredTasks() {
        XCTAssertEqual(CreateReminderListSection.headerTitleKey, "create.tasks.today.section-header")
        XCTAssertFalse(CreateReminderListSection.showsHeader(reminderCount: 0))
        XCTAssertTrue(CreateReminderListSection.showsHeader(reminderCount: 1))
    }

    func testReminderCompletionHapticOnlyPlaysWhenToggledOn() {
        XCTAssertEqual(CreateReminderCompletionFeedback.feedback(isCompleted: true), .createTaskSubmit)
        XCTAssertNil(CreateReminderCompletionFeedback.feedback(isCompleted: false))
    }

    func testReminderSwipeOnlyTracksLeftDragAndDeletesAfterThreshold() {
        XCTAssertEqual(CreateReminderSwipeAction.minimumDistance, 0)
        XCTAssertTrue(CreateReminderSwipeAction.shouldTrackSwipe(translation: CGSize(width: -24, height: 4)))
        XCTAssertFalse(CreateReminderSwipeAction.shouldTrackSwipe(translation: CGSize(width: -4, height: 24)))
        XCTAssertFalse(CreateReminderSwipeAction.shouldTrackSwipe(translation: CGSize(width: 24, height: 4)))
        XCTAssertEqual(CreateReminderSwipeAction.offset(for: 24), 0)
        XCTAssertEqual(CreateReminderSwipeAction.offset(for: -24), -24 * NomaScale.taskDeleteSwipeDamping)
        XCTAssertFalse(CreateReminderSwipeAction.shouldDelete(offset: -24))
        XCTAssertFalse(CreateReminderSwipeAction.shouldDelete(offset: CreateReminderSwipeAction.offset(for: -24)))
        XCTAssertTrue(CreateReminderSwipeAction.shouldDelete(offset: -CreateReminderSwipeAction.deleteThreshold))
    }

    func testReminderSwipeProgressTracksDeleteThreshold() {
        XCTAssertEqual(CreateReminderSwipeAction.progress(for: 0), 0)
        XCTAssertEqual(CreateReminderSwipeAction.remainingProgress(for: 0), 1)
        XCTAssertEqual(
            CreateReminderSwipeAction.progress(for: -CreateReminderSwipeAction.deleteThreshold),
            1
        )
        XCTAssertEqual(
            CreateReminderSwipeAction.remainingProgress(for: -CreateReminderSwipeAction.deleteThreshold),
            0
        )
    }

    func testReminderSwipeFeedbackOnlyPlaysWhenCrossingDeleteThreshold() {
        XCTAssertEqual(
            CreateReminderSwipeAction.feedback(previousOffset: -24, currentOffset: -CreateReminderSwipeAction.deleteThreshold),
            .createTaskSubmit
        )
        XCTAssertNil(
            CreateReminderSwipeAction.feedback(
                previousOffset: -CreateReminderSwipeAction.deleteThreshold,
                currentOffset: -CreateReminderSwipeAction.deleteThreshold - 1
            )
        )
        XCTAssertNil(CreateReminderSwipeAction.feedback(previousOffset: 0, currentOffset: -24))
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

}
