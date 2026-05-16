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
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
