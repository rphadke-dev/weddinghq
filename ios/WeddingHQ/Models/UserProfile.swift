import Foundation

struct UserProfile: Codable, Equatable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
    }
}

struct ProfileSettings: Codable, Equatable {
    let profileId: UUID
    var animationsEnabled: Bool
    var theme: String
    var pushNotificationsEnabled: Bool
    var widgetsEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case animationsEnabled = "animations_enabled"
        case theme
        case pushNotificationsEnabled = "push_notifications_enabled"
        case widgetsEnabled = "widgets_enabled"
    }
}

struct Wedding: Codable, Equatable, Identifiable {
    let id: UUID
    let inviteCode: String
    let title: String
    var weddingDate: String?
    var venueName: String?
    var subscriptionStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case inviteCode = "invite_code"
        case title
        case weddingDate = "wedding_date"
        case venueName = "venue_name"
        case subscriptionStatus = "subscription_status"
    }
}

struct WeddingMemberRow: Codable {
    let weddingId: UUID
    let role: String
    let weddings: Wedding?

    enum CodingKeys: String, CodingKey {
        case weddingId = "wedding_id"
        case role
        case weddings
    }
}
