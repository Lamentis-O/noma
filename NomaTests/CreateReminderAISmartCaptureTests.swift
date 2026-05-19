@testable import Noma
import XCTest

final class CreateReminderAISmartCaptureTests: XCTestCase {
    func testFreeTierKeepsBaseCaptureAndDoesNotCallModel() async {
        let project = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000071")!, title: "Work")
        let model = OnDeviceFoundationModelService(
            client: UnavailableFoundationModelClient()
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "Send update #work",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000072")!,
            projects: [project],
            selectedProjectID: nil,
            tier: .free,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Send update")
        XCTAssertEqual(result?.reminder.projectID, project.id)
    }

    func testProSmartCaptureUsesModelTitleAndSuggestedProjectID() async {
        let project = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000073")!, title: "Health")
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"{"title":"Morgen 9 Uhr Zahnarzt","projectID":"00000000-0000-0000-0000-000000000073","projectTitle":"Health"}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "morgen 9 uhr zahnarzt",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000074")!,
            projects: [project],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Morgen 9 Uhr Zahnarzt")
        XCTAssertEqual(result?.reminder.projectID, project.id)
    }

    func testProSmartCaptureHonorsExplicitProjectOverModelSuggestion() async {
        let work = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000075")!, title: "Work")
        let home = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000076")!, title: "Home")
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"{"title":"Send launch update","projectID":"00000000-0000-0000-0000-000000000076","projectTitle":"Home"}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "Work: Send launch update",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000077")!,
            projects: [work, home],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Send launch update")
        XCTAssertEqual(result?.reminder.projectID, work.id)
    }

    func testProSmartCaptureFallsBackWhenModelReturnsInvalidJSON() async {
        let project = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000078")!, title: "Work")
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(response: "I would put this in Work.")
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "Send update #work",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000079")!,
            projects: [project],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Send update")
        XCTAssertEqual(result?.reminder.projectID, project.id)
    }

    func testProSmartCaptureFallsBackWhenSuggestedProjectIsUnknown() async {
        let selectedProject = TaskProject(id: UUID(uuidString: "00000000-0000-0000-0000-000000000080")!, title: "Inbox")
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"{"title":"Send update","projectID":"00000000-0000-0000-0000-000000000081","projectTitle":"Sales"}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "Send update",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000082")!,
            projects: [selectedProject],
            selectedProjectID: selectedProject.id,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Send update")
        XCTAssertEqual(result?.reminder.projectID, selectedProject.id)
    }

    func testProSmartCapturePreservesModelTitleNewlines() async {
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"{"title":"Buy milk\nPick up keys","projectID":null,"projectTitle":null}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "buy milk\npick up keys",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000083")!,
            projects: [],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Buy milk\nPick up keys")
    }

    func testProSmartCaptureFallsBackWhenModelReturnsEmptyTitle() async {
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"{"title":"","projectID":null,"projectTitle":null}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "Tomorrow 9am !",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000084")!,
            projects: [],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Tomorrow 9am !")
    }

    func testSmartCaptureParsesFirstValidJSONObject() async {
        let model = OnDeviceFoundationModelService(
            client: CapturingFoundationModelClient(
                response: #"I matched {Work}. {"title":"Send update","projectID":null,"projectTitle":null}"#
            )
        )

        let result = await CreateReminderAISmartCapture.submit(
            text: "send update",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000085")!,
            projects: [],
            selectedProjectID: nil,
            tier: .pro,
            foundationModel: model
        )

        XCTAssertEqual(result?.reminder.text, "Send update")
    }
}

private struct CapturingFoundationModelClient: OnDeviceFoundationModelClient {
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

private struct UnavailableFoundationModelClient: OnDeviceFoundationModelClient {
    func availability() -> OnDeviceFoundationModelAvailability {
        XCTFail("Free smart capture must not check Foundation Models availability.")
        return .available
    }

    func generateResponse(
        prompt _: String,
        instructions _: String,
        maximumResponseTokens _: Int?
    ) async throws -> String {
        XCTFail("Free smart capture must not generate a Foundation Models response.")
        return #"{"title":"Ignored","projectID":null,"projectTitle":null}"#
    }
}
