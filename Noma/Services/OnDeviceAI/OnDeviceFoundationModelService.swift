import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum OnDeviceFoundationModelAvailability: Equatable {
    case available
    case locked
    case unsupported
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
}

enum OnDeviceFoundationModelError: Error, Equatable {
    case emptyPrompt
    case unavailable(OnDeviceFoundationModelAvailability)
}

protocol OnDeviceFoundationModelClient: Sendable {
    func availability() -> OnDeviceFoundationModelAvailability
    func generateResponse(
        prompt: String,
        instructions: String,
        maximumResponseTokens: Int?
    ) async throws -> String
}

@Observable
final class OnDeviceFoundationModelService {
    @ObservationIgnored private let client: any OnDeviceFoundationModelClient

    init(client: any OnDeviceFoundationModelClient = AppleOnDeviceFoundationModelClient()) {
        self.client = client
    }

    func availability(for tier: SubscriptionTier) -> OnDeviceFoundationModelAvailability {
        guard tier.canUseOnDeviceFoundationModels else { return .locked }
        return client.availability()
    }

    func generateResponse(
        prompt: String,
        instructions: String,
        tier: SubscriptionTier,
        maximumResponseTokens: Int? = nil
    ) async throws -> String {
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPrompt.isEmpty else { throw OnDeviceFoundationModelError.emptyPrompt }

        let modelAvailability = availability(for: tier)
        guard modelAvailability == .available else {
            throw OnDeviceFoundationModelError.unavailable(modelAvailability)
        }

        return try await client.generateResponse(
            prompt: normalizedPrompt,
            instructions: instructions,
            maximumResponseTokens: maximumResponseTokens
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct AppleOnDeviceFoundationModelClient: OnDeviceFoundationModelClient {
    func availability() -> OnDeviceFoundationModelAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.nomaAvailability
        }
        #endif

        return .unsupported
    }

    func generateResponse(
        prompt: String,
        instructions: String,
        maximumResponseTokens: Int?
    ) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: instructions)
            let options = GenerationOptions(maximumResponseTokens: maximumResponseTokens)
            let response = try await session.respond(to: prompt, options: options)
            return response.content
        }
        #endif

        throw OnDeviceFoundationModelError.unavailable(.unsupported)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private extension SystemLanguageModel {
    var nomaAvailability: OnDeviceFoundationModelAvailability {
        switch availability {
        case .available:
            .available
        case .unavailable(.deviceNotEligible):
            .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            .modelNotReady
        }
    }
}
#endif
