import Foundation

struct EdgeFunctionErrorEnvelope: Codable {
    let error: EdgeFunctionErrorBody
}

struct EdgeFunctionErrorBody: Codable {
    let code: String
    let message: String
}

enum AppError: LocalizedError {
    case message(String)
    case edge(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        case .edge(_, let message): return message
        }
    }
}
