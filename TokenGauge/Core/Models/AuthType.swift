import Foundation

enum AuthType: String, Codable, Sendable {
    case oauthKeychain    // Claude Code → Keychain 자동
    case sessionCookie    // 브라우저 쿠키 → 수동 입력
    case apiKey           // API 키 → 수동 입력
}
