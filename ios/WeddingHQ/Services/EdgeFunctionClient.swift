import Foundation
import Supabase

struct EdgeFunctionClient {
    private let client = SupabaseManager.shared.client

    func invoke<T: Decodable, B: Encodable>(
        _ name: String,
        body: B
    ) async throws -> T {
        try await client.functions.invoke(
            name,
            options: FunctionInvokeOptions(body: body)
        )
    }

    func invoke<T: Decodable>(
        _ name: String
    ) async throws -> T {
        try await client.functions.invoke(name)
    }
}
