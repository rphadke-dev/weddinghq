import Foundation
import Supabase

struct CompleteOnboardingRequest: Encodable {
    let step: String
    var roleIntent: String?
    var displayName: String?
    var bio: String?

    enum CodingKeys: String, CodingKey {
        case step
        case roleIntent = "role_intent"
        case displayName = "display_name"
        case bio
    }
}

struct CompleteOnboardingResponse: Decodable {
    let onboarding: OnboardingProgress
}

struct OnboardingService {
    private let client = SupabaseManager.shared.client
    private let edge = EdgeFunctionClient()

    func fetchProgress() async throws -> OnboardingProgress {
        try await client
            .from("onboarding_progress")
            .select()
            .single()
            .execute()
            .value
    }

    func completeStep(
        _ step: OnboardingStep,
        roleIntent: RoleIntent? = nil,
        displayName: String? = nil,
        bio: String? = nil
    ) async throws -> OnboardingProgress {
        let body = CompleteOnboardingRequest(
            step: step.rawValue,
            roleIntent: roleIntent?.rawValue,
            displayName: displayName,
            bio: bio
        )
        let response: CompleteOnboardingResponse = try await edge.invoke(
            "complete-onboarding-step",
            body: body
        )
        return response.onboarding
    }
}
