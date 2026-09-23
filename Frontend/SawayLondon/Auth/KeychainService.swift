//
//  KeychainService.swift
//  SafeWay London
//

import Foundation
import Security

enum KeychainService {
    private static let service = "com.safewaylondon.app"
    private static let tokenKey = "jwt_token"
    private static let userKey = "user_data"

    /// Save JWT token to Keychain
    static func saveToken(_ token: String) throws {
        try saveData(token.data(using: .utf8)!, forKey: tokenKey)
    }

    /// Retrieve JWT token from Keychain
    static func getToken() throws -> String? {
        guard let data = try getData(forKey: tokenKey) else { return nil }
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return token
    }

    /// Delete JWT token from Keychain
    static func deleteToken() throws {
        try deleteData(forKey: tokenKey)
    }

    /// Save the user (never the password) to Keychain
    static func saveUser(_ user: User) throws {
        let data = try JSONEncoder().encode(user)
        try saveData(data, forKey: userKey)
    }

    /// Get the saved user. Returns nil if nothing is saved or it can't be decoded
    static func getUser() throws -> User? {
        guard let data = try getData(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    /// Delete the stored user from Keychain
    static func deleteUser() throws {
        try deleteData(forKey: userKey)
    }

    // MARK: - Generic Keychain storage

    private static func saveData(_ data: Data, forKey key: String) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    private static func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unableToRetrieve
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    private static func deleteData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error, LocalizedError {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unableToSave:
            return "Unable to save to Keychain"
        case .unableToRetrieve:
            return "Unable to retrieve from Keychain"
        case .unableToDelete:
            return "Unable to delete from Keychain"
        case .invalidData:
            return "Invalid Keychain data"
        }
    }
}
