import AuthenticationServices
import Foundation
import UIKit

extension AppleSignInAuthenticator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                finish(.failure(AppleSignInError.invalidCredential))
                return
            }

            guard
                let identityToken = appleIDCredential.identityToken,
                let identityTokenString = String(data: identityToken, encoding: .utf8)
            else {
                finish(.failure(AppleSignInError.invalidIdentityToken))
                return
            }

            guard let nonce = currentNonce else {
                finish(.failure(AppleSignInError.missingNonce))
                return
            }

            finish(
                .success(
                    AppleSignInCredential(
                        identityToken: identityTokenString,
                        nonce: nonce,
                        fullName: appleIDCredential.fullName
                    )
                )
            )
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            finish(.failure(error))
        }
    }
}

extension AppleSignInAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windowScenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }

            if let keyWindow = windowScenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) {
                return keyWindow
            }

            if let windowScene = windowScenes.first(where: { $0.activationState == .foregroundActive }) ?? windowScenes.first {
                return ASPresentationAnchor(windowScene: windowScene)
            }

            preconditionFailure("Apple sign-in requires an active window scene.")
        }
    }
}
