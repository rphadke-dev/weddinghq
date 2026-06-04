import Foundation
import Supabase
import AuthenticationServices

@MainActor
final class AuthService {
    private let client = SupabaseManager.shared.client

    static let redirectURL = URL(string: "weddinghq://auth-callback")!

    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> Session? {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.session
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> Session {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signInWithGoogle() async throws -> URL {
        try await client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: Self.redirectURL
        )
    }

    func session(from url: URL) async throws -> Session {
        try await client.auth.session(from: url)
    }

    func signInWithPhone(phone: String) async throws {
        try await client.auth.signInWithOTP(phone: phone)
    }

    func verifyPhoneOTP(phone: String, token: String) async throws -> Session {
        let response = try await client.auth.verifyOTP(
            phone: phone,
            token: token,
            type: .sms
        )
        guard let session = response.session else {
            throw AppError.message("Phone verification did not return a session.")
        }
        return session
    }

    func signInWithEmailOTP(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: Self.redirectURL
        )
    }
}
