import Foundation

enum ClaudeAPIError: Error, LocalizedError, Equatable {
    case invalidURL
    case httpError(Int)
    case rateLimited
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 API URL"
        case .httpError(let code): return "HTTP 오류: \(code)"
        case .rateLimited: return "요청 제한 (429)"
        case .noData: return "응답 데이터 없음"
        }
    }
}

enum ClaudeAPI {
    static func fetchUsage(token: String) async throws -> ClaudeUsageResponse {
        guard let url = URL(string: Constants.apiBaseURL + Constants.usageEndpoint) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.betaHeader, forHTTPHeaderField: "anthropic-beta")
        request.setValue(Constants.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.noData
        }

        if httpResponse.statusCode == 429 {
            throw ClaudeAPIError.rateLimited
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeAPIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
    }
}
