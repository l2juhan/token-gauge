import Foundation

enum ClaudeAuthError: Error, LocalizedError {
    case noCredentials
    case invalidFormat
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .noCredentials: return "Claude Code 자격증명 없음"
        case .invalidFormat: return "자격증명 형식 오류"
        case .tokenExpired: return "OAuth 토큰 만료 (Claude Code 재로그인 필요)"
        }
    }
}

enum ClaudeAuthService {
    static func getAccessToken() throws -> String {
        let data = try KeychainHelper.read(service: Constants.claudeKeychainService)
        let credentials = try JSONDecoder().decode(ClaudeCredentials.self, from: data)

        guard let oauth = credentials.claudeAiOauth else {
            throw ClaudeAuthError.invalidFormat
        }

        if let expiresAt = oauth.expiresAt {
            let expiryDate = Date(timeIntervalSince1970: expiresAt / 1000.0)
            if expiryDate < Date() {
                throw ClaudeAuthError.tokenExpired
            }
        }

        return oauth.accessToken
    }
}
