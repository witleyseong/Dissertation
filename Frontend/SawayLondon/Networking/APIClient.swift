//
//  APIClient.swift
//  SafeWay London
//

import Foundation

enum APIClient {
    /// Shared URLSession with custom configuration
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeoutInterval
        config.timeoutIntervalForResource = APIConfig.timeoutInterval * 2
        return URLSession(configuration: config)
    }()

    /// Generic request with Codable response
    static func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Codable? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if provided
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // encode the body (not logged because it can have the password)
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        #if DEBUG
        print("\(method.rawValue) \(endpoint)")
        #endif

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("Response: \(httpResponse.statusCode)")
            #endif

            // response is not logged either (login returns the token)
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            default:
                throw mapError(statusCode: httpResponse.statusCode, data: data)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw classifyNetworkError(error)
        }
    }

    /// Simple request without expecting a response body
    static func requestNoResponse(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Codable? = nil,
        token: String? = nil
    ) async throws {
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw classifyNetworkError(error)
        }
    }

    /// Turns an error status code into an APIError
    static func mapError(statusCode: Int, data: Data) -> APIError {
        func backendMessage() -> String? {
            try? JSONDecoder().decode(ErrorResponse.self, from: data).error
        }

        switch statusCode {
        case 400:
            return .badRequest(backendMessage() ?? "Invalid request")
        case 401:
            return .unauthorized(backendMessage() ?? "Unauthorized")
        case 404:
            return .notFound
        case 409:
            return .conflict(backendMessage() ?? "Conflict")
        case 429:
            return .tooManyRequests
        case 500:
            return .serverError
        case 502:
            return .badGateway(backendMessage() ?? "Service unavailable")
        case 503:
            return .serviceUnavailable
        default:
            return .httpError(statusCode)
        }
    }

    /// Turns a network error into an APIError (timeout, no connection, ...)
    static func classifyNetworkError(_ error: Error) -> APIError {
        guard let urlError = error as? URLError else {
            return .networkError(error)
        }
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        default:
            return .networkError(urlError)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case badRequest(String)
    case unauthorized(String)
    case conflict(String)
    case badGateway(String)
    case tooManyRequests
    case serverError
    case serviceUnavailable
    case notFound
    case timeout
    case noConnection
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request"
        case .invalidResponse:
            return "The server sent an unexpected response. Please try again."
        case .badRequest(let message):
            return message
        case .unauthorized(let message):
            return message
        case .conflict(let message):
            return message
        case .badGateway(let message):
            return "The journey service is temporarily unavailable: \(message)"
        case .tooManyRequests:
            return "Too many requests. Please wait a moment and try again."
        case .serverError:
            return "Something went wrong on our end. Please try again shortly."
        case .serviceUnavailable:
            return "The service is temporarily unavailable. Please try again shortly."
        case .notFound:
            return "The requested resource could not be found."
        case .timeout:
            return "The request timed out. Please check your connection and try again."
        case .noConnection:
            return "No internet connection. Please check your network and try again."
        case .httpError(let code):
            return "Something went wrong (error \(code)). Please try again."
        case .decodingError:
            return "We couldn't read the server's response. Please try again."
        case .networkError:
            return "A network error occurred. Please check your connection and try again."
        }
    }

    // compare by case only, because Error itself isn't Equatable
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL), (.invalidResponse, .invalidResponse),
             (.tooManyRequests, .tooManyRequests), (.serverError, .serverError),
             (.serviceUnavailable, .serviceUnavailable), (.notFound, .notFound),
             (.timeout, .timeout), (.noConnection, .noConnection):
            return true
        case let (.badRequest(a), .badRequest(b)),
             let (.unauthorized(a), .unauthorized(b)),
             let (.conflict(a), .conflict(b)),
             let (.badGateway(a), .badGateway(b)):
            return a == b
        case let (.httpError(a), .httpError(b)):
            return a == b
        case (.decodingError, .decodingError), (.networkError, .networkError):
            return true
        default:
            return false
        }
    }
}
