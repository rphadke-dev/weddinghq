import Foundation
import Supabase

enum AppRoute: Equatable {
    case welcome
    case auth
    case onboarding
    case main
}

@MainActor
final class AppState: ObservableObject {
    @Published var route: AppRoute = .welcome
    @Published var session: Session?
    @Published var onboarding: OnboardingProgress?
    @Published var profile: UserProfile?
    @Published var isLoading = true
    @Published var bannerMessage: String?

    private let client = SupabaseManager.shared.client
    private let onboardingService = OnboardingService()
    private let profileService = ProfileService()

    func bootstrap() async {
        defer { isLoading = false }
        do {
            session = try await client.auth.session
            try await refreshUserState()
        } catch {
            session = nil
            route = .welcome
        }
    }

    func refreshUserState() async throws {
        guard session != nil else {
            route = .welcome
            return
        }
        onboarding = try await onboardingService.fetchProgress()
        profile = try await profileService.fetchProfile()
        if onboarding?.currentStep == "completed" {
            route = .main
        } else {
            route = .onboarding
        }
    }

    func signedIn(session: Session) async {
        self.session = session
        isLoading = true
        defer { isLoading = false }
        do {
            try await refreshUserState()
        } catch {
            bannerMessage = error.localizedDescription
            route = .onboarding
        }
    }

    func signedOut() async {
        try? await client.auth.signOut()
        session = nil
        onboarding = nil
        profile = nil
        route = .welcome
    }

    func finishWelcome() {
        if session != nil {
            Task { try? await refreshUserState() }
        } else {
            route = .auth
        }
    }

    func showAuth() {
        route = .auth
    }
}
