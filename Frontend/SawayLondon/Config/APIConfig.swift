//
//  APIConfig.swift
//  SafeWay London
//

import Foundation

enum APIConfig {
    /// Base URL of the SafeWay backend API (single constant - change it here only).
    ///
    /// Default: `http://localhost:3000`. This works when the app runs in the iOS
    static let baseURL = "http://localhost:3000"
    
    /// Timeout interval for API requests (in seconds)
    static let timeoutInterval: TimeInterval = 30
    
    /// JWT token expiration buffer (refresh if expiring within this many seconds)
    static let tokenExpirationBuffer: TimeInterval = 3600 // 1 hour
}
