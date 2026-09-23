//
//  Journey.swift
//  SafeWay London
//

import Foundation
import CoreLocation
import SwiftUI

struct JourneyResponse: Codable {
    let journeys: [Journey]
    let message: String?
    // only set when TfL found several places for the text (journeys is empty then)
    let disambiguation: JourneyDisambiguation?
}

/// One place the user can pick when the search text was ambiguous. lat/lon are sent back as from/to.
struct JourneyLocationCandidate: Codable, Identifiable, Hashable {
    let name: String?
    let lat: Double
    let lon: Double

    var id: String { "\(lat),\(lon)" }

    var displayName: String { name ?? "\(lat), \(lon)" }
}

struct JourneyDisambiguation: Codable {
    let origin: [JourneyLocationCandidate]?
    let destination: [JourneyLocationCandidate]?
}

struct Journey: Codable, Identifiable, Equatable {
    let id: String
    let duration: Int // minutes
    let departureTime: String  // "HH:mm" format (e.g., "22:04")
    let arrivalTime: String    // "HH:mm" format
    let numChanges: Int

    // old fields from the first version of the API, not shown in the UI
    let safetyScore: Double?
    let riskLevel: RiskLevel?

    // New backend fields (preferred)
    let exposureScore: Double?
    let exposureLevel: String?  // "lower" | "moderate" | "higher"
    let isFastest: Bool?
    let isLowestExposure: Bool?

    // null when the journey has no walking
    let totalCrimeExposure: Int?
    let totalWalkingKm: Double?
    let exposurePerKm: Double?

    let fare: Double?  // Real TfL fare in pounds, may be null
    let crimeBreakdown: [String: Int] // Missing/null decodes to an empty dictionary
    let legs: [Leg]

    enum CodingKeys: String, CodingKey {
        case id, duration, departureTime, arrivalTime, numChanges
        case safetyScore, riskLevel, exposureScore, exposureLevel
        case isFastest, isLowestExposure
        case totalCrimeExposure, totalWalkingKm, exposurePerKm
        case fare, crimeBreakdown, legs
    }

    init(
        id: String,
        duration: Int,
        departureTime: String,
        arrivalTime: String,
        numChanges: Int,
        safetyScore: Double?,
        riskLevel: RiskLevel? = nil,
        exposureScore: Double?,
        exposureLevel: String?,
        isFastest: Bool?,
        isLowestExposure: Bool?,
        totalCrimeExposure: Int?,
        totalWalkingKm: Double?,
        exposurePerKm: Double?,
        fare: Double?,
        crimeBreakdown: [String: Int],
        legs: [Leg]
    ) {
        self.id = id
        self.duration = duration
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.numChanges = numChanges
        self.safetyScore = safetyScore
        self.riskLevel = riskLevel
        self.exposureScore = exposureScore
        self.exposureLevel = exposureLevel
        self.isFastest = isFastest
        self.isLowestExposure = isLowestExposure
        self.totalCrimeExposure = totalCrimeExposure
        self.totalWalkingKm = totalWalkingKm
        self.exposurePerKm = exposurePerKm
        self.fare = fare
        self.crimeBreakdown = crimeBreakdown
        self.legs = legs
    }

    /// Custom decoder so null exposure fields or a missing crimeBreakdown don't break decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        duration = try container.decode(Int.self, forKey: .duration)
        departureTime = try container.decode(String.self, forKey: .departureTime)
        arrivalTime = try container.decode(String.self, forKey: .arrivalTime)
        numChanges = try container.decode(Int.self, forKey: .numChanges)
        safetyScore = try container.decodeIfPresent(Double.self, forKey: .safetyScore)
        riskLevel = try container.decodeIfPresent(RiskLevel.self, forKey: .riskLevel)
        exposureScore = try container.decodeIfPresent(Double.self, forKey: .exposureScore)
        exposureLevel = try container.decodeIfPresent(String.self, forKey: .exposureLevel)
        isFastest = try container.decodeIfPresent(Bool.self, forKey: .isFastest)
        isLowestExposure = try container.decodeIfPresent(Bool.self, forKey: .isLowestExposure)
        totalCrimeExposure = try container.decodeIfPresent(Int.self, forKey: .totalCrimeExposure)
        totalWalkingKm = try container.decodeIfPresent(Double.self, forKey: .totalWalkingKm)
        exposurePerKm = try container.decodeIfPresent(Double.self, forKey: .exposurePerKm)
        fare = try container.decodeIfPresent(Double.self, forKey: .fare)
        crimeBreakdown = try container.decodeIfPresent([String: Int].self, forKey: .crimeBreakdown) ?? [:]
        legs = try container.decode([Leg].self, forKey: .legs)
    }

    // Computed property for display
    var fareDisplay: String? {
        guard let fare = fare else { return nil }
        return String(format: "£%.2f", fare)
    }
    
    // User-facing exposure label
    var exposureLabel: String {
        // Prefer new exposureLevel over legacy riskLevel
        guard let level = exposureLevel?.lowercased() else {
            return "Exposure information unavailable"
        }
        
        switch level {
        case "lower":
            return "Lower exposure"
        case "moderate":
            return "Moderate exposure"
        case "higher":
            return "Higher exposure"
        default:
            return "Exposure information unavailable"
        }
    }
    
    // Equatable conformance (compare by id)
    static func == (lhs: Journey, rhs: Journey) -> Bool {
        lhs.id == rhs.id
    }
}

struct Leg: Codable, Identifiable, Equatable {
    // made once here because the backend has no leg id (a computed UUID would change every time)
    let id: String = UUID().uuidString
    
    let isWalking: Bool
    let modeId: String
    let mode: String
    let routeName: String?
    let duration: Int // minutes
    let crimeCount: Int?
    
    // Legacy field (kept for backwards compatibility)
    let riskLevel: RiskLevel?
    
    // New backend fields (preferred)
    let exposureLevel: String?  // "lower" | "moderate" | "higher"
    let walkingKm: Double?
    let exposurePerKm: Double?
    
    let lineString: [[Double]] // [lng, lat]
    let midpoint: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case isWalking, modeId, mode, routeName, duration
        case crimeCount, riskLevel, exposureLevel
        case walkingKm, exposurePerKm
        case lineString, midpoint
    }
    
    /// Convert lineString to CLLocationCoordinate2D array
    var coordinates: [CLLocationCoordinate2D] {
        lineString.compactMap { $0.asCoordinate }
    }
    
    /// Midpoint as coordinate
    var midpointCoordinate: CLLocationCoordinate2D? {
        midpoint?.asCoordinate
    }
    
    /// Exposure band for walking legs (maps backend values to user-facing labels)
    var exposureBand: ExposureBand? {
        guard isWalking else { return nil }
        
        // Prefer new exposureLevel if available
        if let level = exposureLevel?.lowercased() {
            switch level {
            case "lower":
                return .lower
            case "moderate":
                return .moderate
            case "higher":
                return .higher
            default:
                break
            }
        }
        
        // Fallback to legacy riskLevel
        return riskLevel?.exposureBand
    }
    
    /// Distance in meters (haversine)
    var distanceMeters: Double {
        let coords = coordinates
        guard coords.count >= 2 else { return 0 }
        
        var total: Double = 0
        for i in 0..<(coords.count - 1) {
            total += coords[i].distance(to: coords[i + 1])
        }
        return total
    }
    
    /// Display label for this leg
    var displayLabel: String {
        if isWalking {
            return "Walk \(duration) min"
        } else if modeId == "bus", let route = routeName {
            return "Bus \(route)"
        } else if modeId == "tube", let route = routeName {
            return "\(route) line"
        } else {
            // Fallback
            return routeName ?? mode.capitalized
        }
    }
    
    /// Icon for this leg
    var iconName: String {
        if isWalking {
            return "figure.walk"
        } else if modeId == "bus" {
            return "bus.fill"
        } else if modeId == "tube" {
            return "tram.fill"
        } else {
            return "arrow.forward"
        }
    }
    
    /// Departure coordinate (first point in lineString)
    var departureCoordinate: CLLocationCoordinate2D? {
        lineString.first?.asCoordinate
    }
    
    /// Arrival coordinate (last point in lineString)
    var arrivalCoordinate: CLLocationCoordinate2D? {
        lineString.last?.asCoordinate
    }
    
    /// Path as coordinate array (alias for coordinates)
    var path: [CLLocationCoordinate2D] {
        coordinates
    }
    
    /// Distance in kilometers
    var distanceKm: Double? {
        distanceMeters > 0 ? distanceMeters / 1000.0 : nil
    }
    
    /// From location name (inferred from backend or defaults)
    var from: String {
        // This would ideally come from backend, for now use generic labels
        if isWalking {
            return "Your location"
        } else if modeId == "bus", let route = routeName {
            return "Bus \(route)"
        } else if modeId == "tube", let route = routeName {
            return "\(route) line"
        } else {
            return mode.capitalized
        }
    }
    
    /// To location name (inferred from backend or defaults)
    var to: String {
        // This would ideally come from backend, for now use generic labels
        "Next stop"
    }
    
    /// Get the official colour for London Underground/Overground/DLR lines
    var tubeLineColor: Color {
        guard modeId == "tube", let lineName = routeName?.lowercased() else {
            return Color(hex: "#1D4E89") // Default blue
        }
        
        // Official TfL colours for each line
        switch lineName {
        // Underground lines
        case let name where name.contains("bakerloo"):
            return Color(hex: "#B36305") // Brown
        case let name where name.contains("central"):
            return Color(hex: "#E32017") // Red
        case let name where name.contains("circle"):
            return Color(hex: "#FFD300") // Yellow
        case let name where name.contains("district"):
            return Color(hex: "#00782A") // Green
        case let name where name.contains("hammersmith") || name.contains("city"):
            return Color(hex: "#F3A9BB") // Pink
        case let name where name.contains("jubilee"):
            return Color(hex: "#A0A5A9") // Grey
        case let name where name.contains("metropolitan"):
            return Color(hex: "#9B0056") // Magenta
        case let name where name.contains("northern"):
            return Color(hex: "#000000") // Black
        case let name where name.contains("piccadilly"):
            return Color(hex: "#003688") // Dark blue
        case let name where name.contains("victoria"):
            return Color(hex: "#0098D4") // Light blue
        case let name where name.contains("waterloo") || name.contains("city"):
            return Color(hex: "#95CDBA") // Turquoise
        // Overground & others
        case let name where name.contains("overground"):
            return Color(hex: "#EE7C0E") // Orange
        case let name where name.contains("elizabeth"):
            return Color(hex: "#7156A5") // Purple
        case let name where name.contains("dlr"):
            return Color(hex: "#00A4A7") // Teal
        case let name where name.contains("tram"):
            return Color(hex: "#84B817") // Green
        default:
            return Color(hex: "#1D4E89") // Default blue
        }
    }
    
    /// Color for risk circle (if walking with risk data)
    var riskCircleColor: Color? {
        guard isWalking, let risk = riskLevel else { return nil }
        switch risk {
        case .high:
            return Color(hex: "#B3541E") // Red
        case .moderate:
            return Color(hex: "#B26A00") // Orange
        case .safe, .low:
            return Color(hex: "#2E7D32") // Green
        }
    }
    
    /// Should show risk circle on map
    var shouldShowRiskCircle: Bool {
        isWalking && midpoint != nil && riskLevel != nil
    }
    
    // Equatable conformance
    static func == (lhs: Leg, rhs: Leg) -> Bool {
        lhs.modeId == rhs.modeId &&
        lhs.isWalking == rhs.isWalking &&
        lhs.lineString == rhs.lineString
    }
}

struct ExposureRequest: Codable {
    let coordinates: [[Double]] // [lng, lat]
    let bufferMeters: Int?
}

struct ExposureResponse: Codable {
    let userId: String
    let crimeCount: Int
    let walkingKm: Double
    let exposurePerKm: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case crimeCount = "crime_count"
        case walkingKm = "walking_km"
        case exposurePerKm = "exposure_per_km"
    }

    /// Custom decoder: the backend's user_id may arrive as a JSON string or a JSON number.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decodeFlexibleIDString(forKey: .userId)
        crimeCount = try container.decode(Int.self, forKey: .crimeCount)
        walkingKm = try container.decode(Double.self, forKey: .walkingKm)
        exposurePerKm = try container.decode(Double.self, forKey: .exposurePerKm)
    }
}

struct RecentSearch: Codable, Identifiable {
    let id: String
    let from: String
    let to: String
    let date: Date
    
    init(from: String, to: String, date: Date = Date()) {
        self.id = UUID().uuidString
        self.from = from
        self.to = to
        self.date = date
    }
}

// MARK: - Journey Computed Metrics

extension Journey {
    /// Total walking distance in meters
    var totalWalkingDistanceMeters: Double {
        legs.filter { $0.isWalking }.reduce(0) { $0 + $1.distanceMeters }
    }
    
    /// Total walking distance in kilometers
    var totalWalkingDistanceKm: Double {
        totalWalkingDistanceMeters / 1000.0
    }
    
    /// Number of walking segments
    var walkingSegments: Int {
        legs.filter { $0.isWalking }.count
    }
}

// MARK: - Route Selection

extension Array where Element == Journey {
    /// The fastest journey (backend flag first, otherwise the shortest duration)
    var fastestJourney: Journey? {
        if let flagged = first(where: { $0.isFastest == true }) {
            return flagged
        }
        return self.min { $0.duration < $1.duration }
    }

    /// The lowest exposure journey (backend flag first, otherwise the smallest exposurePerKm).
    /// Uses per km and not the total, because the walking distance is different in each route.
    var lowestExposureJourney: Journey? {
        if let flagged = first(where: { $0.isLowestExposure == true }) {
            return flagged
        }
        let measured = compactMap { journey -> (Journey, Double)? in
            guard let exposurePerKm = journey.exposurePerKm else { return nil }
            return (journey, exposurePerKm)
        }
        return measured.min { $0.1 < $1.1 }?.0
    }
}

extension Journey {
    /// How much lower (in %) the exposure per km is compared to another journey.
    /// nil if either one has no exposurePerKm, the baseline is 0, or it is not actually lower.
    func exposureReductionPercentage(comparedTo other: Journey) -> Double? {
        guard let baseline = exposurePerKm, let otherExposure = other.exposurePerKm,
              baseline > 0 else {
            return nil
        }
        let reduction = ((baseline - otherExposure) / baseline) * 100
        return reduction > 0 ? reduction : nil
    }
}
