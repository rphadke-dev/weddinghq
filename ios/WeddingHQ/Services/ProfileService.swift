import Foundation
import Supabase

struct ProfileService {
    private let client = SupabaseManager.shared.client

    func fetchProfile() async throws -> UserProfile {
        try await client.from("profiles").select().single().execute().value
    }

    func updateProfile(displayName: String?, bio: String?) async throws -> UserProfile {
        struct Patch: Encodable {
            var displayName: String?
            var bio: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
                case bio
            }
        }
        return try await client
            .from("profiles")
            .update(Patch(displayName: displayName, bio: bio))
            .select()
            .single()
            .execute()
            .value
    }

    func fetchSettings() async throws -> ProfileSettings {
        try await client.from("profile_settings").select().single().execute().value
    }

    func updateSettings(_ settings: ProfileSettings) async throws -> ProfileSettings {
        try await client
            .from("profile_settings")
            .update(settings)
            .eq("profile_id", value: settings.profileId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchWeddings() async throws -> [Wedding] {
        let rows: [WeddingMemberRow] = try await client
            .from("wedding_members")
            .select("wedding_id, role, weddings(*)")
            .execute()
            .value
        return rows.compactMap(\.weddings)
    }
}
