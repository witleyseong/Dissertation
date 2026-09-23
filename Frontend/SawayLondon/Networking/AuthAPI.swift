//
//  AuthAPI.swift
//  SafeWay London
//

import Foundation

enum AuthAPI {
    /// POST /api/auth/register
    static func register(email: String, password: String) async throws -> RegisterResponse {
        struct RegisterRequest: Codable {
            let email: String
            let password: String
        }
        
        let body = RegisterRequest(email: email, password: password)
        
        return try await APIClient.request(
            endpoint: "/api/auth/register",
            method: .post,
            body: body
        )
    }
    
    /// POST /api/auth/login
    static func login(email: String, password: String) async throws -> AuthResponse {
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }
        
        let body = LoginRequest(email: email, password: password)
        
        return try await APIClient.request(
            endpoint: "/api/auth/login",
            method: .post,
            body: body
        )
    }
    
    /// GET /api/health
    static func checkHealth() async throws -> HealthResponse {
        return try await APIClient.request(
            endpoint: "/api/health",
            method: .get
        )
    }
}

enum JourneyAPI {
    /// POST /api/journey
    static func planJourney(from: String, to: String, token: String?) async throws -> JourneyResponse {
        struct JourneyRequest: Codable {
            let from: String
            let to: String
        }
        
        let body = JourneyRequest(from: from, to: to)
        
        return try await APIClient.request(
            endpoint: "/api/journey",
            method: .post,
            body: body,
            token: token
        )
    }
    
    /// POST /api/routes/exposure (requires auth)
    static func calculateExposure(
        coordinates: [[Double]],
        bufferMeters: Int? = nil,
        token: String
    ) async throws -> ExposureResponse {
        let body = ExposureRequest(coordinates: coordinates, bufferMeters: bufferMeters)
        
        return try await APIClient.request(
            endpoint: "/api/routes/exposure",
            method: .post,
            body: body,
            token: token
        )
    }
}
