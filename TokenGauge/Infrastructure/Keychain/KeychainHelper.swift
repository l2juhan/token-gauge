import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case unexpectedData
    case osError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound: return "Keychain 항목 없음 (Claude Code 로그인 필요)"
        case .unexpectedData: return "Keychain 데이터 형식 오류"
        case .osError(let status): return "Keychain 오류: \(status)"
        }
    }
}

enum KeychainHelper {
    static func read(service: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.osError(status)
        }
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        return data
    }
}
