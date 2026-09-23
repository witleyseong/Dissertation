//
//  User.swift
//  SafeWay London
//

import Foundation

struct User: Codable, Equatable {
    let id: String
    let email: String
    let plan: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, plan
        case createdAt = "created_at"
    }

    init(id: String, email: String, plan: String, createdAt: String? = nil) {
        self.id = id
        self.email = email
        self.plan = plan
        self.createdAt = createdAt
    }

    /// Custom decoder: the backend's user id may arrive as a JSON string or a JSON number.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleIDString(forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        plan = try container.decode(String.self, forKey: .plan)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct RegisterResponse: Codable {
    let user: User
}

struct ErrorResponse: Codable {
    let error: String
}

struct HealthResponse: Codable {
    let status: String
    let crimesInDb: Int?
    
    enum CodingKeys: String, CodingKey {
        case status
        case crimesInDb = "crimes_in_db"
    }
}
