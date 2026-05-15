import Foundation

extension CreateView {
    nonisolated static func shouldApplyInitialFocus(_ delay: () async throws -> Void) async -> Bool {
        do {
            try await delay()
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
