import Foundation

enum AppConfig {
    static var supabaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? "http://127.0.0.1:54321"
        guard let url = URL(string: raw) else {
            fatalError("Invalid SUPABASE_URL: \(raw)")
        }
        return url
    }

    static var supabaseAnonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
            ?? ""
    }
}
