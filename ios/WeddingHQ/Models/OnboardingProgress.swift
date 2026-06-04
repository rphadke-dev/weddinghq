import Foundation

struct OnboardingProgress: Codable, Equatable {
    let profileId: UUID
    var roleIntent: String?
    var currentStep: String
    var completedSteps: [String]
    var completedAt: String?

    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case roleIntent = "role_intent"
        case currentStep = "current_step"
        case completedSteps = "completed_steps"
        case completedAt = "completed_at"
    }
}

enum RoleIntent: String, CaseIterable, Identifiable {
    case couple
    case guest
    case vendor
    case coordinator

    var id: String { rawValue }

    var title: String {
        switch self {
        case .couple: return "Couple"
        case .guest: return "Guest"
        case .vendor: return "Vendor"
        case .coordinator: return "Day-of coordinator"
        }
    }
}

enum OnboardingStep: String {
    case welcomeSeen = "welcome_seen"
    case roleSelected = "role_selected"
    case profileBasics = "profile_basics"
    case weddingCreateOrJoin = "wedding_create_or_join"
    case subscriptionPrompt = "subscription_prompt"
    case completed
}
