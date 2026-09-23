//
//  ExposureBand.swift
//  SafeWay London
//

import Foundation
import SwiftUI

/// Three exposure bands for UI display
/// Maps from backend values to user-facing labels
enum ExposureBand: String, CaseIterable {
    case lower = "Lower exposure"
    case moderate = "Moderate exposure"
    case higher = "Higher exposure"
    
    /// Hex color for this band
    var color: Color {
        switch self {
        case .lower:
            return Color(hex: "#2E7D32")  // Green
        case .moderate:
            return Color(hex: "#B26A00")  // Amber
        case .higher:
            return Color(hex: "#B3541E")  // Orange-red
        }
    }
    
    /// Line dash pattern for map
    var dashPattern: [Double] {
        return [4, 4] // Dotted pattern for all walking legs
    }
    
    /// Line width (relative)
    var lineWidth: Double {
        switch self {
        case .lower, .moderate:
            return 4.0
        case .higher:
            return 5.0
        }
    }
    
    /// Symbol for map
    var hasSymbol: Bool {
        switch self {
        case .lower:
            return false
        case .moderate, .higher:
            return true
        }
    }
    
    /// Accessibility label
    var accessibilityLabel: String {
        switch self {
        case .lower:
            return "Lower recorded-crime exposure"
        case .moderate:
            return "Moderate recorded-crime exposure"
        case .higher:
            return "Higher recorded-crime exposure"
        }
    }
}

/// Backend risk level (4 levels) - legacy field, DO NOT display directly
/// Use exposureLevel (string) or ExposureBand for user-facing labels
enum RiskLevel: String, Codable {
    case safe
    case low
    case moderate
    case high
    
    /// Map to the three UI exposure bands
    var exposureBand: ExposureBand {
        switch self {
        case .safe, .low:
            return .lower
        case .moderate:
            return .moderate
        case .high:
            return .higher
        }
    }
}
