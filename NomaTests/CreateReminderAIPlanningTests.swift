@testable import Noma
import XCTest

final class CreateReminderAIPlanningTests: XCTestCase {
    func testAutomaticPlanningRunsAfterUserAddsTaskWhenProAndNotAlreadyPlanning() {
        XCTAssertEqual(
            CreateReminderAIPlanningTrigger.actionAfterUserAddedTask(
                canUseOnDeviceFoundationModels: true,
                isPlanningDay: false
            ),
            .startNow
        )
    }

    func testAutomaticPlanningSchedulesAnotherPassWhenUserAddsTaskDuringPlanning() {
        XCTAssertEqual(
            CreateReminderAIPlanningTrigger.actionAfterUserAddedTask(
                canUseOnDeviceFoundationModels: true,
                isPlanningDay: true
            ),
            .scheduleAfterCurrentPlanning
        )
    }

    func testAutomaticPlanningDoesNotRunForFreeTier() {
        XCTAssertEqual(
            CreateReminderAIPlanningTrigger.actionAfterUserAddedTask(
                canUseOnDeviceFoundationModels: false,
                isPlanningDay: false
            ),
            .skip
        )
    }

    func testPlanningResultIsIgnoredAfterDayChanges() {
        XCTAssertFalse(
            CreateReminderAIPlanningResultAcceptance.acceptsResult(
                originatingDayID: "2026-05-19",
                activeDayID: "2026-05-20"
            )
        )
    }

    func testPlanningResultIsAcceptedForOriginatingDay() {
        XCTAssertTrue(
            CreateReminderAIPlanningResultAcceptance.acceptsResult(
                originatingDayID: "2026-05-19",
                activeDayID: "2026-05-19"
            )
        )
    }

    func testCarryForwardFallsBackWhenAIPlanRecommendsNoItems() {
        let reminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000107")!,
            text: "Send report"
        )
        let plan = CreateReminderAIPlanningResult(
            organizedTasks: [],
            carryForwardReminderIDs: []
        )

        XCTAssertEqual(
            CreateReminderCarryForwardAIRecommendation.reminders(from: [reminder], using: plan),
            [reminder]
        )
    }

    func testFreeTierDoesNotCallModel() async {
        let currentReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            text: "Write update"
        )
        let model = OnDeviceFoundationModelService(client: UnavailableAIPlanningModelClient())

        let result = await CreateReminderAIPlanning.plan(
            currentReminders: [currentReminder],
            carryForwardReminders: [],
            projects: [],
            tier: .free,
            foundationModel: model,
            localeIdentifier: "en_US"
        )

        XCTAssertNil(result)
    }

    func testProPlanUsesValidOrganizationMetadata() async {
        let firstReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            text: "Ship build"
        )
        let secondReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
            text: "Send invoice"
        )
        let model = OnDeviceFoundationModelService(
            client: CapturingAIPlanningModelClient(
                response: #"{"taskOrganization":[{"id":"00000000-0000-0000-0000-000000000103","priorityRank":1,"category":"finance"},{"id":"00000000-0000-0000-0000-000000000102","priorityRank":2,"category":"release"}],"carryForwardReminderIDs":[]}"#
            )
        )

        let result = await CreateReminderAIPlanning.plan(
            currentReminders: [firstReminder, secondReminder],
            carryForwardReminders: [],
            projects: [],
            tier: .pro,
            foundationModel: model,
            localeIdentifier: "en_US"
        )

        XCTAssertEqual(
            result?.organizedTasks,
            [
                CreateReminderAIOrganizedTask(reminderID: secondReminder.id, priorityRank: 1, category: "finance"),
                CreateReminderAIOrganizedTask(reminderID: firstReminder.id, priorityRank: 2, category: "release")
            ]
        )
        XCTAssertEqual(result?.carryForwardReminderIDs, [])
    }

    func testProPlanDropsUnknownOrganizationIDsAndWrongCarryForwardBucketIDs() async {
        let currentReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000104")!,
            text: "Review launch notes"
        )
        let carryForwardReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000105")!,
            text: "Book dentist"
        )
        let model = OnDeviceFoundationModelService(
            client: CapturingAIPlanningModelClient(
                response: #"{"taskOrganization":[{"id":"00000000-0000-0000-0000-000000000104","priorityRank":0,"category":""},{"id":"00000000-0000-0000-0000-000000000199","priorityRank":1,"category":"unknown"}],"carryForwardReminderIDs":["00000000-0000-0000-0000-000000000104","00000000-0000-0000-0000-000000000105"]}"#
            )
        )

        let result = await CreateReminderAIPlanning.plan(
            currentReminders: [currentReminder],
            carryForwardReminders: [carryForwardReminder],
            projects: [],
            tier: .pro,
            foundationModel: model,
            localeIdentifier: "en_US"
        )

        XCTAssertEqual(
            result?.organizedTasks,
            [CreateReminderAIOrganizedTask(reminderID: currentReminder.id, priorityRank: 1, category: "general")]
        )
        XCTAssertEqual(result?.carryForwardReminderIDs, [carryForwardReminder.id])
    }

    func testProPlanReturnsNilForInvalidJSON() async {
        let currentReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000106")!,
            text: "Write update"
        )
        let model = OnDeviceFoundationModelService(
            client: CapturingAIPlanningModelClient(response: "Focus on the update.")
        )

        let result = await CreateReminderAIPlanning.plan(
            currentReminders: [currentReminder],
            carryForwardReminders: [],
            projects: [],
            tier: .pro,
            foundationModel: model,
            localeIdentifier: "en_US"
        )

        XCTAssertNil(result)
    }
}

private struct CapturingAIPlanningModelClient: OnDeviceFoundationModelClient {
    let response: String

    func availability() -> OnDeviceFoundationModelAvailability {
        .available
    }

    func generateResponse(
        prompt _: String,
        instructions _: String,
        maximumResponseTokens _: Int?
    ) async throws -> String {
        response
    }
}

private struct UnavailableAIPlanningModelClient: OnDeviceFoundationModelClient {
    func availability() -> OnDeviceFoundationModelAvailability {
        XCTFail("Free task organization must not check Foundation Models availability.")
        return .available
    }

    func generateResponse(
        prompt _: String,
        instructions _: String,
        maximumResponseTokens _: Int?
    ) async throws -> String {
        XCTFail("Free task organization must not generate a Foundation Models response.")
        return #"{"taskOrganization":[],"carryForwardReminderIDs":[]}"#
    }
}
