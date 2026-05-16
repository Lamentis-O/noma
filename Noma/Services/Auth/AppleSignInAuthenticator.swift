import AuthenticationServices
import Foundation

@MainActor
final class AppleSignInAuthenticator: NSObject, AppleSignInProviding {
    private var continuation: CheckedContinuation<AppleSignInCredential, Error>?
    private var authorizationController: ASAuthorizationController?
    var currentNonce: String?

    func requestCredential() async throws -> AppleSignInCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            do {
                let nonce = try AppleSignInNonceFactory.makeRandomNonceString()
                currentNonce = nonce

                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                request.nonce = AppleSignInNonceFactory.sha256(nonce)

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                authorizationController = controller
                controller.performRequests()
            } catch {
                self.continuation = nil
                authorizationController = nil
                continuation.resume(throwing: error)
            }
        }
    }

    func finish(_ result: Result<AppleSignInCredential, Error>) {
        let continuation = continuation
        self.continuation = nil
        authorizationController = nil
        currentNonce = nil

        switch result {
        case .success(let credential):
            continuation?.resume(returning: credential)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }
}
