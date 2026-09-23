//
//  RouteComparisonView.swift
//  SafeWay London
//

import SwiftUI

struct RouteComparisonView: View {
    let journeys: [Journey] // All 3 journeys
    
    @State private var selectedJourney: Journey?

    // uses the helpers in Models/Journey.swift (backend flags first, then duration / exposurePerKm)
    private var fastestJourney: Journey? { journeys.fastestJourney }
    private var lowestExposureJourney: Journey? { journeys.lowestExposureJourney }

    private func badges(for journey: Journey) -> [JourneyBadge] {
        var badges: [JourneyBadge] = []
        
        let isFastest = journey.id == fastestJourney?.id
        let isLowestExposure = journey.id == lowestExposureJourney?.id
        
        if isFastest && isLowestExposure {
            badges.append(.fastest)
            badges.append(.lowestExposure)
        } else if isFastest {
            badges.append(.fastest)
        } else if isLowestExposure {
            badges.append(.lowestExposure)
        } else {
            badges.append(.balanced)
        }
        
        return badges
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header summary
                if let fastest = fastestJourney, let lowestExp = lowestExposureJourney {
                    if fastest.id == lowestExp.id {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                            
                            Text("Best route")
                                .font(.title2.bold())
                            
                            Text("Fastest option with lowest recorded-crime exposure")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else if let reduction = fastest.exposureReductionPercentage(comparedTo: lowestExp) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title)
                                .foregroundStyle(.green)

                            Text(String(format: "%.0f%% less exposure", reduction))
                                .font(.title2.bold())

                            Text("by choosing the lower-exposure route")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Journey cards
                ForEach(journeys) { journey in
                    JourneyCard(
                        journey: journey,
                        badges: badges(for: journey)
                    ) {
                        selectedJourney = journey
                    }
                }
                
                DisclaimerBar()
            }
            .padding()
        }
        .navigationTitle("Compare routes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedJourney) { journey in
            MapDetailView(journey: journey)
        }
    }
}

// Badge type
enum JourneyBadge {
    case fastest
    case lowestExposure
    case balanced
    
    var label: String {
        switch self {
        case .fastest: return "Fastest"
        case .lowestExposure: return "Lowest Exposure"
        case .balanced: return "Balanced"
        }
    }
    
    var color: Color {
        switch self {
        case .fastest: return .blue
        case .lowestExposure: return .green
        case .balanced: return .orange
        }
    }
}

struct JourneyCard: View {
    let journey: Journey
    let badges: [JourneyBadge]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Badges and chevron
                HStack {
                    ForEach(badges, id: \.label) { badge in
                        Text(badge.label)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(badge.color)
                            .foregroundStyle(.white)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Duration and times
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(journey.duration.formatDuration())
                        .font(.title.bold())
                    
                    Text("\(journey.departureTime) - \(journey.arrivalTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()

                // Visual route overview (like Google Maps)
                RouteOverview(legs: journey.legs)

                Divider()

                // walking distance, walking segments and exposure per walking km, straight from the backend
                VStack(spacing: 8) {
                    MetricRow(
                        icon: "figure.walk",
                        label: "Walking distance",
                        value: journey.totalWalkingDistanceMeters.formatDistance()
                    )
                    MetricRow(
                        icon: "arrow.triangle.branch",
                        label: "Walking segments",
                        value: "\(journey.walkingSegments)"
                    )
                    MetricRow(
                        icon: "clock.arrow.circlepath",
                        label: "Historical exposure",
                        value: journey.exposurePerKm.map { String(format: "%.1f crimes/km", $0) } ?? "Unavailable",
                        footer: "Recorded crimes/km walked, based on historical data"
                    )
                }

                // Bottom info: changes and fare
                HStack {
                    if journey.numChanges > 0 {
                        Label("\(journey.numChanges) change\(journey.numChanges == 1 ? "" : "s")", systemImage: "arrow.triangle.swap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Direct", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    if let fareDisplay = journey.fareDisplay {
                        Text(fareDisplay)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Visual overview of route like Google Maps: walk -> bus 24 -> walk -> tube Central -> walk
struct RouteOverview: View {
    let legs: [Leg]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                    HStack(spacing: 4) {
                        // Mode icon
                        Image(systemName: leg.iconName)
                            .font(.subheadline)
                            .foregroundStyle(leg.isWalking ? .green : .blue)
                        
                        // Route name for transit
                        if !leg.isWalking, let routeName = leg.routeName {
                            Text(routeName)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        } else if leg.isWalking {
                            // Show duration for walking
                            Text("\(leg.duration)m")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Arrow between segments
                        if index < legs.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    var footer: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline.bold())
            }
            
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RouteComparisonView(
            journeys: [
                Journey(
                    id: "1",
                    duration: 30,
                    departureTime: "10:00",
                    arrivalTime: "10:30",
                    numChanges: 2,
                    safetyScore: nil,
                    exposureScore: nil,
                    exposureLevel: "moderate",
                    isFastest: true,
                    isLowestExposure: false,
                    totalCrimeExposure: 50,
                    totalWalkingKm: nil,
                    exposurePerKm: nil,
                    fare: 2.80,
                    crimeBreakdown: [:],
                    legs: []
                ),
                Journey(
                    id: "2",
                    duration: 35,
                    departureTime: "10:00",
                    arrivalTime: "10:35",
                    numChanges: 1,
                    safetyScore: nil,
                    exposureScore: nil,
                    exposureLevel: "lower",
                    isFastest: false,
                    isLowestExposure: true,
                    totalCrimeExposure: 25,
                    totalWalkingKm: nil,
                    exposurePerKm: nil,
                    fare: 2.80,
                    crimeBreakdown: [:],
                    legs: []
                ),
                Journey(
                    id: "3",
                    duration: 33,
                    departureTime: "10:00",
                    arrivalTime: "10:33",
                    numChanges: 3,
                    safetyScore: nil,
                    exposureScore: nil,
                    exposureLevel: "moderate",
                    isFastest: false,
                    isLowestExposure: false,
                    totalCrimeExposure: 40,
                    totalWalkingKm: nil,
                    exposurePerKm: nil,
                    fare: 3.20,
                    crimeBreakdown: [:],
                    legs: []
                )
            ]
        )
    }
}
