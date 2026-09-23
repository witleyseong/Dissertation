//
//  SessionStore.swift
//  SafeWay London
//

import Foundation

@Observable
final class SessionStore {
    enum State {
        case loading
        case signedOut
        case signedIn(User)
    }
    
    private(set) var state: State = .loading
    private var currentToken: String?
    
    init() {
        Task { await loadSession() }
    }
    
    /// Restore the session from Keychain when the app opens (no network call)
    @MainActor
    func loadSession() async {
        do {
            guard let token = try KeychainService.getToken() else {
                state = .signedOut
                return
            }

            guard let claims = decodeJWT(token), !isTokenExpired(claims) else {
                // no valid token, nothing to restore
                try? KeychainService.deleteToken()
                try? KeychainService.deleteUser()
                state = .signedOut
                return
            }

            guard let user = try KeychainService.getUser() else {
                // token is ok but the saved user is missing, so start signed out
                try? KeychainService.deleteToken()
                try? KeychainService.deleteUser()
                state = .signedOut
                return
            }

            currentToken = token
            state = .signedIn(user)
        } catch {
            try? KeychainService.deleteToken()
            try? KeychainService.deleteUser()
            state = .signedOut
        }
    }
    
    /// Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async throws {
        let authResponse = try await AuthAPI.login(email: email, password: password)

        // save token and user for the next launch (never the password)
        try KeychainService.saveToken(authResponse.token)
        try KeychainService.saveUser(authResponse.user)
        currentToken = authResponse.token

        state = .signedIn(authResponse.user)
    }
    
    /// Sign up with email and password, then auto-login
    @MainActor
    func signUp(email: String, password: String) async throws {
        // Register first
        _ = try await AuthAPI.register(email: email, password: password)
        
        // Then login
        try await signIn(email: email, password: password)
    }
    
    /// Sign out and clear session
    @MainActor
    func signOut() {
        try? KeychainService.deleteToken()
        try? KeychainService.deleteUser()

        currentToken = nil
        state = .signedOut
    }
    
    /// Handle 401 unauthorized - clear session
    @MainActor
    func handleUnauthorized() {
        signOut()
    }
    
    /// Get current auth token for API calls
    func getToken() -> String? {
        return currentToken
    }
    
    /// Get current user
    var currentUser: User? {
        if case .signedIn(let user) = state {
            return user
        }
        return nil
    }
    
    // MARK: - JWT Helpers
    
    private func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        let payloadSegment = segments[1]
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Pad to multiple of 4
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    private func isTokenExpired(_ claims: [String: Any]) -> Bool {
        guard let exp = claims["exp"] as? TimeInterval else { return true }
        let expirationDate = Date(timeIntervalSince1970: exp)
        let bufferDate = Date().addingTimeInterval(APIConfig.tokenExpirationBuffer)
        return expirationDate < bufferDate
    }
}
