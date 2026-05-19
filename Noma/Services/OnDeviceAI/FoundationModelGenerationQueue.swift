import Foundation

actor FoundationModelGenerationQueue {
    private var isGenerating = false
    private var waitingContinuations: [CheckedContinuation<Void, Never>] = []

    func generate(_ operation: @Sendable () async throws -> String) async throws -> String {
        await waitForTurn()

        do {
            try Task.checkCancellation()
            let response = try await generateWithRetry(operation)
            finishTurn()
            return response
        } catch {
            finishTurn()
            throw error
        }
    }

    private func waitForTurn() async {
        guard isGenerating else {
            isGenerating = true
            return
        }

        await withCheckedContinuation { continuation in
            waitingContinuations.append(continuation)
        }
    }

    private func finishTurn() {
        guard !waitingContinuations.isEmpty else {
            isGenerating = false
            return
        }

        waitingContinuations.removeFirst().resume()
    }

    private func generateWithRetry(_ operation: @Sendable () async throws -> String) async throws -> String {
        do {
            return try await operation()
        } catch let error where shouldRetry(error) {
            return try await operation()
        }
    }

    private func shouldRetry(_ error: Error) -> Bool {
        if Task.isCancelled { return false }
        if error is CancellationError { return true }
        return error as? OnDeviceFoundationModelError == .emptyResponse
    }
}
