@testable import Noma
import XCTest

final class OnDeviceFoundationModelServiceTests: XCTestCase {
    func testFreeTierLocksFoundationModelAccess() async throws {
        let service = OnDeviceFoundationModelService(client: StubOnDeviceFoundationModelClient())

        XCTAssertEqual(service.availability(for: .free), .locked)

        do {
            _ = try await service.generateResponse(
                prompt: "Summarize my day",
                instructions: "Be concise.",
                tier: .free
            )
            XCTFail("Free tier should not call the on-device Foundation Model.")
        } catch let error as OnDeviceFoundationModelError {
            XCTAssertEqual(error, .unavailable(.locked))
        }
    }

    func testProTierCanUseAvailableFoundationModel() async throws {
        let service = OnDeviceFoundationModelService(
            client: StubOnDeviceFoundationModelClient(response: "  Plan the next task.  ")
        )

        let response = try await service.generateResponse(
            prompt: "  Help me prioritize  ",
            instructions: "Return one short sentence.",
            tier: .pro,
            maximumResponseTokens: 40
        )

        XCTAssertEqual(service.availability(for: .pro), .available)
        XCTAssertEqual(response, "Plan the next task.")
    }

    func testProTierSurfacesUnavailableFoundationModelState() async throws {
        let service = OnDeviceFoundationModelService(
            client: StubOnDeviceFoundationModelClient(availability: .modelNotReady)
        )

        do {
            _ = try await service.generateResponse(
                prompt: "Help me prioritize",
                instructions: "Return one short sentence.",
                tier: .pro
            )
            XCTFail("Unavailable model state should be surfaced before generation.")
        } catch let error as OnDeviceFoundationModelError {
            XCTAssertEqual(error, .unavailable(.modelNotReady))
        }
    }

    func testFoundationModelServiceRejectsEmptyPrompts() async throws {
        let service = OnDeviceFoundationModelService(client: StubOnDeviceFoundationModelClient())

        do {
            _ = try await service.generateResponse(
                prompt: "   \n",
                instructions: "Return one short sentence.",
                tier: .pro
            )
            XCTFail("Empty prompts should not reach the model.")
        } catch let error as OnDeviceFoundationModelError {
            XCTAssertEqual(error, .emptyPrompt)
        }
    }
}

private struct StubOnDeviceFoundationModelClient: OnDeviceFoundationModelClient {
    var availabilityValue: OnDeviceFoundationModelAvailability = .available
    var response: String = "Done"

    init(
        availability: OnDeviceFoundationModelAvailability = .available,
        response: String = "Done"
    ) {
        availabilityValue = availability
        self.response = response
    }

    func availability() -> OnDeviceFoundationModelAvailability {
        availabilityValue
    }

    func generateResponse(
        prompt _: String,
        instructions _: String,
        maximumResponseTokens _: Int?
    ) async throws -> String {
        response
    }
}
