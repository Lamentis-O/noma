import Foundation
import Observation

enum AuthRootPhase: Equatable { case loading, signedOut, signedIn }

struct AuthSessionSnapshot: Equatable {
    let isSignedIn: Bool
    var rootPhase: AuthRootPhase { isSignedIn ? .signedIn : .signedOut }
}

struct AppleSignInCredential: Equatable {
    let identityToken: String
    let nonce: String
    let fullName: PersonNameComponents?
}

@MainActor
protocol AppleSignInProviding { func requestCredential() async throws -> AppleSignInCredential }

@MainActor
@Observable
final class AuthStateManager {
    private let authClient: any AuthClient
    private let appleSignInProvider: any AppleSignInProviding
    private var authObserverTask: Task<Void, Never>?
    private var hasStarted = false

    var phase: AuthRootPhase = .loading
    var errorMessage: String?
    var isSigningIn = false

    convenience init() {
        self.init(authClient: SupabaseClientProvider.makeAuthClient())
    }

    convenience init(authClient: any AuthClient) {
        self.init(authClient: authClient, appleSignInProvider: AppleSignInAuthenticator())
    }

    init(
        authClient: any AuthClient,
        appleSignInProvider: any AppleSignInProviding
    ) {
        self.authClient = authClient
        self.appleSignInProvider = appleSignInProvider
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        authObserverTask = Task { [authClient] in
            apply(await authClient.currentSessionSnapshot())

            for await snapshot in authClient.authStateSnapshots() {
                apply(snapshot)
            }
        }
    }

    func signInWithApple() {
        guard beginSignInWithApple() else { return }
        Task { await completeSignInWithAppleFlow() }
    }

    func signInWithAppleFlow() async {
        guard beginSignInWithApple() else { return }
        await completeSignInWithAppleFlow()
    }

    func signOut() { Task { await signOutFlow() } }

    func signOutFlow() async {
        errorMessage = nil
        do {
            try await authClient.signOut()
            apply(AuthSessionSnapshot(isSignedIn: false))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func beginSignInWithApple() -> Bool {
        guard !isSigningIn else { return false }
        errorMessage = nil
        isSigningIn = true
        return true
    }

    private func completeSignInWithAppleFlow() async {
        defer { isSigningIn = false }

        do {
            let credential = try await appleSignInProvider.requestCredential()
            let snapshot = try await authClient.signInWithApple(
                idToken: credential.identityToken,
                nonce: credential.nonce
            )
            apply(snapshot)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ snapshot: AuthSessionSnapshot) {
        phase = snapshot.rootPhase
    }
}
