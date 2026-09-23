//
//  FlexibleID.swift
//  SafeWay London
//

import Foundation

extension KeyedDecodingContainer {
    /// Decodes a backend identifier field that may arrive as a JSON string ("1") or a JSON
    /// number (1), always returning it as a String. Throws for any other JSON type (bool,
    /// array, object) rather than silently accepting it.
    func decodeFlexibleIDString(forKey key: Key) throws -> String {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected a String or Int identifier for key '\(key.stringValue)'"
            )
        )
    }
}
