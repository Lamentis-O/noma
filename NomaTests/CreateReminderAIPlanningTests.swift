@testable import Noma
import XCTest

final class CreateReminderAIPlanningTests: XCTestCase {
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

    func testProPlanUsesValidModelIDs() async {
        let currentReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            text: "Ship build"
        )
        let carryForwardReminder = CreateReminder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
            text: "Send invoice"
        )
        let model = OnDeviceFoundationModelService(
            client: CapturingAIPlanningModelClient(
                response: #"{"summary":"Start with the build, then bring forward the invoice.","focusReminderID":"00000000-0000-0000-0000-000000000102","carryForwardReminderIDs":["00000000-0000-0000-0000-000000000103"],"deferredReminderIDs":[]}"#
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

        XCTAssertEqual(result?.summary, "Start with the build, then bring forward the invoice.")
        XCTAssertEqual(result?.focusReminderID, currentReminder.id)
        XCTAssertEqual(result?.carryForwardReminderIDs, [carryForwardReminder.id])
        XCTAssertEqual(result?.deferredReminderIDs, [])
    }

    func testProPlanDropsUnknownAndWrongBucketIDs() async {
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
                response: #"{"summary":"Keep launch first.","focusReminderID":"00000000-0000-0000-0000-000000000199","carryForwardReminderIDs":["00000000-0000-0000-0000-000000000104","00000000-0000-0000-0000-000000000105"],"deferredReminderIDs":["00000000-0000-0000-0000-000000000105","00000000-0000-0000-0000-000000000199"]}"#
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

        XCTAssertNil(result?.focusReminderID)
        XCTAssertEqual(result?.carryForwardReminderIDs, [carryForwardReminder.id])
        XCTAssertEqual(result?.deferredReminderIDs, [carryForwardReminder.id])
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
        XCTFail("Free daily planning must not check Foundation Models availability.")
        return .available
    }

    func generateResponse(
        prompt _: String,
        instructions _: String,
        maximumResponseTokens _: Int?
    ) async throws -> String {
        XCTFail("Free daily planning must not generate a Foundation Models response.")
        return #"{"summary":"Ignored","focusReminderID":null,"carryForwardReminderIDs":[],"deferredReminderIDs":[]}"#
    }
}
