import Foundation

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case invalidIdentityToken
    case missingNonce
    case randomNonceGenerationFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            "Apple did not return a valid credential."
        case .invalidIdentityToken:
            "Apple did not return a valid identity token."
        case .missingNonce:
            "Apple sign in nonce was lost."
        case .randomNonceGenerationFailed:
            "Could not create a secure Apple sign in nonce."
        }
    }
}
