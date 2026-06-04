import Foundation

struct CreateWeddingRequest: Encodable {
    let title: String
    var weddingDate: String?
    var venueName: String?

    enum CodingKeys: String, CodingKey {
        case title
        case weddingDate = "wedding_date"
        case venueName = "venue_name"
    }
}

struct CreateWeddingResponse: Decodable {
    let wedding: Wedding
    let requiresSubscription: Bool?

    enum CodingKeys: String, CodingKey {
        case wedding
        case requiresSubscription = "requires_subscription"
    }
}

struct JoinWeddingRequest: Encodable {
    let inviteCode: String
    var roleIntent: String?

    enum CodingKeys: String, CodingKey {
        case inviteCode = "invite_code"
        case roleIntent = "role_intent"
    }
}

struct JoinWeddingResponse: Decodable {
    let wedding: Wedding
}

struct GrantSubscriptionRequest: Encodable {
    let weddingId: UUID

    enum CodingKeys: String, CodingKey {
        case weddingId = "wedding_id"
    }
}

struct GrantSubscriptionResponse: Decodable {
    let wedding: Wedding
}

struct WeddingService {
    private let edge = EdgeFunctionClient()

    func createWedding(
        title: String,
        weddingDate: Date?,
        venueName: String?
    ) async throws -> CreateWeddingResponse {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let body = CreateWeddingRequest(
            title: title,
            weddingDate: weddingDate.map { formatter.string(from: $0) },
            venueName: venueName
        )
        return try await edge.invoke("create-wedding", body: body)
    }

    func joinWedding(code: String, roleIntent: RoleIntent) async throws -> JoinWeddingResponse {
        let body = JoinWeddingRequest(
            inviteCode: code.uppercased(),
            roleIntent: roleIntent.rawValue
        )
        return try await edge.invoke("join-wedding", body: body)
    }

    func grantStubSubscription(weddingId: UUID) async throws -> Wedding {
        let body = GrantSubscriptionRequest(weddingId: weddingId)
        let response: GrantSubscriptionResponse = try await edge.invoke(
            "grant-couple-subscription",
            body: body
        )
        return response.wedding
    }
}
