import Foundation
import Supabase

@MainActor
protocol AuthClient {
    func currentSessionSnapshot() async -> AuthSessionSnapshot
    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot>
    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot
    func signOut() async throws
}

struct SupabaseAuthClient: AuthClient {
    let client: SupabaseClient

    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(session: client.auth.currentSession)
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            Task {
                for await (event, session) in client.auth.authStateChanges {
                    continuation.yield(AuthSessionSnapshot(event: event, session: session))
                }
                continuation.finish()
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        _ = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return AuthSessionSnapshot(isSignedIn: true)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}

struct UnconfiguredAuthClient: AuthClient {
    let error: Error

    func currentSessionSnapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(isSignedIn: false)
    }

    func authStateSnapshots() -> AsyncStream<AuthSessionSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSessionSnapshot {
        throw error
    }

    func signOut() async throws {}
}

private extension AuthSessionSnapshot {
    init(session: Session?) {
        guard let session else {
            self.init(state: .missing)
            return
        }

        self.init(state: session.isExpired ? .refreshingExpiredLocalSession : .authenticated)
    }

    init(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .initialSession:
            self.init(session: session)
        case .signedIn, .tokenRefreshed, .userUpdated, .mfaChallengeVerified, .passwordRecovery:
            self.init(session: session)
        case .signedOut, .userDeleted:
            self.init(state: .missing)
        }
    }
}
